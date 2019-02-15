defmodule FCInventory.DraftLineItem do
  @moduledoc false
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

  defstruct [:pending_quantity]

  def interested?(%LineItemCreated{status: "pending", line_item_id: liid}), do: {:start, liid}
  def interested?(%TransactionCreated{line_item_id: liid}), do: {:continue, liid}
  def interested?(%LineItemMarked{original_status: "pending", status: "draft", line_item_id: liid}), do: {:stop, liid}
  def interested?(_), do: false

  def handle(_, %LineItemCreated{} = event) do
    line_item =
      event
      |> Map.take([:stockable_id, :quantity, :account_id])
      |> Map.put(:id, event.line_item_id)

    available_batches = AvailableBatchStore.get(line_item.account_id, line_item.stockable_id)
    create_transactions(line_item, available_batches, line_item.quantity)
  end

  def handle(%{pending_quantity: pq}, %TransactionCreated{quantity: quantity} = txn) do
    if D.cmp(pq, quantity) == :eq do
      %MarkLineItem{
        requester_role: "system",
        account_id: txn.account_id,
        line_item_id: txn.line_item_id,
        status: "drafted"
      }
    end
  end

  def apply(state, %LineItemCreated{quantity: quantity}) do
    %{state | pending_quantity: quantity}
  end

  def apply(%{pending_quantity: pending_quantity} = state, %TransactionCreated{quantity: quantity}) do
    %{state | pending_quantity: D.sub(pending_quantity, quantity)}
  end

  defp create_transactions(line_item, available_batches, quantity) do
    create_transactions(line_item, available_batches, quantity, [])
  end

  defp create_transactions(_, [], _, cmds), do: cmds

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
      line_item_id: line_item.id,
      source_stockable_id: line_item.stockable_id,
      source_type: 'FCInventory.Batch',
      source_id: batch.id,
      quantity: quantity
    }
  end
end
