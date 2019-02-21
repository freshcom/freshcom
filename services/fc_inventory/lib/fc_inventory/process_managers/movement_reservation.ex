defmodule FCInventory.MovementReservation do
  @moduledoc false
  use TypedStruct

  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:9403aad7-38f0-4fbd-a223-d024f212bdae",
    router: FCInventory.Router

  import FCSupport.Struct

  alias Decimal, as: D
  alias FCInventory.LineItem

  alias FCInventory.{
    MarkMovement,
    ReserveStock,
    MarkLineItem,
    AddTransaction
  }

  alias FCInventory.{
    MovementCreated,
    StockReserved,
    StockPartiallyReserved,
    StockReservationFailed,
    MovementMarked,
    LineItemAdded,
    LineItemMarked
  }

  @derive Jason.Encoder

  typedstruct do
    field :line_items, map()
  end

  def interested?(%MovementCreated{status: "pending", line_items: line_items} = event) when map_size(line_items) > 0, do: {:start!, event.movement_id}
  def interested?(%MovementMarked{status: "processing"} = event), do: {:continue!, event.movement_id}

  def interested?(%LineItemAdded{status: "pending"} = event), do: {:start!, event.movement_id}
  def interested?(%LineItemMarked{status: "processing"} = event), do: {:continue!, event.movement_id}
  # def interested?(%LineItemUpdated{} = event) do
  #   # TODO: ...
  # end

  def interested?(%StockReserved{} = event), do: {:continue!, event.movement_id}
  def interested?(%StockPartiallyReserved{} = event), do: {:continue!, event.movement_id}
  def interested?(%StockReservationFailed{} = event), do: {:continue!, event.movement_id}

  def interested?(%MovementMarked{original_status: "processing"} = event), do: {:stop, event.movement_id}

  def interested?(_), do: false

  def handle(_, %MovementCreated{} = event) do
    %MarkMovement{
      requester_role: "system",
      movement_id: event.movement_id,
      status: "processing"
    }
  end

  def handle(%{line_items: line_items}, %MovementMarked{} = event) do
    Enum.map(line_items, fn({id, line_item}) ->
      %ReserveStock{
        requester_role: "system",
        movement_id: event.movement_id,
        line_item_id: id,
        stockable_id: line_item.stockable_id,
        quantity: D.sub(line_item.quantity, line_item.quantity_processed)
      }
    end)
  end

  def handle(_, %LineItemAdded{status: "pending"} = event) do
    %MarkLineItem{
      requester_role: "system",
      movement_id: event.movement_id,
      line_item_id: event.line_item_id,
      status: "processing"
    }
  end

  def handle(_, %et{} = event) when et in [StockReserved, StockPartiallyReserved] do
    txn_cmds =
      Enum.map(event.transactions, fn {id, transaction} ->
        %AddTransaction{
          requester_role: "system",
          account_id: event.account_id,
          movement_id: event.movement_id,
          line_item_id: event.line_item_id,
          source_batch_id: transaction.source_batch_id,
          transaction_id: id,
          status: transaction.status,
          quantity: transaction.quantity
        }
      end)

    mark_cmd = %MarkLineItem{
      requester_role: "system",
      account_id: event.account_id,
      movement_id: event.movement_id,
      line_item_id: event.line_item_id,
      status: "processed"
    }

    txn_cmds ++ [mark_cmd]
  end

  def handle(_, %StockReservationFailed{} = event) do
    %MarkLineItem{
      requester_role: "system",
      movement_id: event.movement_id,
      line_item_id: event.line_item_id,
      status: "none_reserved"
    }
  end

  def apply(state, %MovementCreated{line_items: line_items}) do
    %{state | line_items: line_items}
  end

  def apply(state, %LineItemAdded{} = event) do
    line_item = merge(%LineItem{}, event)

    %{state | line_items: %{event.line_item_id => line_item}}
  end
end
