defmodule FCInventory.DraftLineItem do
  @moduledoc false
  use TypedStruct
  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:9403aad7-38f0-4fbd-a223-d024f212bdae",
    router: FCInventory.Router

  alias Decimal, as: D

  alias FCInventory.{
    CreateTransaction,
    MarkLineItem
  }

  alias FCInventory.{
    LineItemCreated,
    TransactionCreated,
    LineItemMarked
  }

  alias FCInventory.AvailableBatchStore

  @derive Jason.Encoder

  typedstruct do
    field :quantity_pending, Decimal.t(), default: D.new(0)
    field :quantity_drafted, Decimal.t(), default: D.new(0)
  end

  def interested?(%LineItemCreated{status: "pending"} = event) do
    available_batches = AvailableBatchStore.get(event.account_id, event.stockable_id)

    case length(available_batches) do
      0 -> false
      _ -> {:start, event.line_item_id}
    end
  end

  def interested?(%TransactionCreated{line_item_id: liid}), do: {:continue, liid}
  def interested?(%LineItemMarked{original_status: "pending", line_item_id: liid}), do: {:stop, liid}
  def interested?(_), do: false

  def handle(_, %LineItemCreated{} = event) do
    line_item =
      event
      |> LineItemCreated.deserialize()
      |> Map.take([:stockable_id, :quantity, :account_id, :cause_id, :cause_type])
      |> Map.put(:id, event.line_item_id)

    available_batches = AvailableBatchStore.get(line_item.account_id, line_item.stockable_id)
    create_transactions(line_item, available_batches, line_item.quantity)
  end

  def handle(%{quantity_pending: qp} = state, %TransactionCreated{} = event) do
    event = TransactionCreated.deserialize(event)

    if D.cmp(qp, event.quantity) == :eq do
      %MarkLineItem{
        requester_role: "system",
        account_id: event.account_id,
        line_item_id: event.line_item_id,
        status: line_item_status(state, event)
      }
    end
  end

  def apply(state, %LineItemCreated{} = event) do
    event = LineItemCreated.deserialize(event)
    %{state | quantity_pending: event.quantity}
  end

  def apply(%{quantity_pending: qp, quantity_drafted: qd} = state, %TransactionCreated{status: "drafted"} = event) do
    event = TransactionCreated.deserialize(event)

    %{
      state |
      quantity_pending: D.sub(qp, event.quantity),
      quantity_drafted: D.add(qd, event.quantity)
    }
  end

  defp create_transactions(line_item, available_batches, quantity) do
    create_transactions(line_item, available_batches, quantity, [])
  end

  defp create_transactions(line_item, [], quantity, cmds) do
    if D.cmp(quantity, D.new(0)) == :gt do
      cmds ++ [%CreateTransaction{
        requester_role: "system",
        account_id: line_item.account_id,
        line_item_id: line_item.id,
        status: "pending",
        quantity: quantity,
        source_stockable_id: line_item.stockable_id,
        destination_type: line_item.cause_type,
        destination_id: line_item.cause_id
      }]
    else
      cmds
    end
  end

  defp create_transactions(line_item, [%{quantity_available: qa} = batch | batches], quantity, cmds) do
    case D.cmp(qa, quantity) do
      :lt ->
        cmd = create_transaction(line_item, batch, qa)
        cmds = cmds ++ [cmd]
        create_transactions(line_item, batches, D.sub(quantity, qa), cmds)

      _ ->
        cmd = create_transaction(line_item, batch, quantity)
        cmds ++ [cmd]
    end
  end

  defp create_transaction(line_item, batch, quantity) do
    %CreateTransaction{
      requester_role: "system",
      account_id: line_item.account_id,
      status: "drafted",
      line_item_id: line_item.id,
      source_stockable_id: line_item.stockable_id,
      source_type: "FCInventory.Batch",
      source_id: batch.id,
      destination_type: line_item.cause_type,
      destination_id: line_item.cause_id,
      quantity: quantity
    }
  end

  defp line_item_status(%{quantity_drafted: qd}, last_event) do
    cond do
      D.cmp(qd, D.new(0)) == :eq ->
        last_event.status

      last_event.status == "pending" ->
        "partially_drafted"

      last_event.status == "drafted" ->
        "drafted"
    end
  end
end
