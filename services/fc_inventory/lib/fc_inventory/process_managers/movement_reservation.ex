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
    ProcessLineItem,
    AddTransaction
  }

  alias FCInventory.{
    MovementCreated,
    StockReserved,
    StockPartiallyReserved,
    StockReservationFailed,
    MovementMarked,
    LineItemAdded,
    LineItemMarked,
    LineItemProcessed,
    LineItemUpdated
  }

  @derive Jason.Encoder

  typedstruct do
    field :line_items, map()
  end

  def interested?(%MovementCreated{status: "pending", line_items: line_items} = event) when map_size(line_items) > 0, do: {:start!, event.movement_id}
  def interested?(%LineItemMarked{status: "reserving"} = event), do: {:continue!, event.movement_id}

  def interested?(%LineItemAdded{status: "pending"} = event), do: {:start!, event.movement_id}
  # def interested?(%LineItemUpdated{effective_keys: ekeys} = event) do
  #   if Enum.member?(ekeys, :quantity) do
  #     {:start!, event.movement_id}
  #   else
  #     false
  #   end
  # end

  def interested?(%StockReserved{} = event), do: {:continue!, event.movement_id}
  def interested?(%StockPartiallyReserved{} = event), do: {:continue!, event.movement_id}
  def interested?(%StockReservationFailed{} = event), do: {:continue!, event.movement_id}

  def interested?(%MovementMarked{original_status: "processing"} = event), do: {:stop, event.movement_id}

  def interested?(_), do: false

  def handle(_, %MovementCreated{line_items: line_items} = event) do
    Enum.reduce(line_items, [], fn({stockable_id, line_item}, cmds) ->
      if line_item.status == "pending" do
        cmd = %MarkLineItem{
          requester_role: "system",
          movement_id: event.movement_id,
          stockable_id: stockable_id,
          status: "reserving"
        }
        cmds ++ [cmd]
      else
        cmds
      end
    end)
  end

  def handle(%{line_items: line_items}, %LineItemMarked{status: "reserving"} = event) do
    line_item = line_items[event.stockable_id]

    %ReserveStock{
      requester_role: "system",
      movement_id: event.movement_id,
      stockable_id: event.stockable_id,
      quantity: line_item.quantity
    }
  end

  def handle(_, %LineItemAdded{status: "pending"} = event) do
    %MarkLineItem{
      requester_role: "system",
      movement_id: event.movement_id,
      stockable_id: event.stockable_id,
      status: "reserving"
    }
  end

  def handle(_, %StockReserved{} = event) do
    %ProcessLineItem{
      requester_role: "system",
      movement_id: event.movement_id,
      stockable_id: event.stockable_id,
      status: "reserved",
      quantity: event.quantity
    }
  end

  def handle(_, %StockPartiallyReserved{} = event) do
    %ProcessLineItem{
      requester_role: "system",
      movement_id: event.movement_id,
      stockable_id: event.stockable_id,
      status: "reserved",
      quantity: event.quantity_reserved
    }
  end

  def handle(_, %StockReservationFailed{} = event) do
    %MarkLineItem{
      requester_role: "system",
      movement_id: event.movement_id,
      stockable_id: event.stockable_id,
      status: "none_reserved"
    }
  end

  def apply(state, %MovementCreated{line_items: line_items}) do
    %{state | line_items: line_items}
  end

  def apply(state, %LineItemAdded{} = event) do
    line_item = merge(%LineItem{}, event)

    %{state | line_items: %{event.stockable_id => line_item}}
  end
end

# defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.MovementReservation do
#   alias FCInventory.LineItem

#   def decode(state) do
#     line_items =
#       Enum.reduce(state.line_items, %{}, fn({stockable_id, line_item}, line_items) ->
#         Map.put(line_items, stockable_id, LineItem.deserialize(line_item))
#       end)

#     %{state | line_items: line_items}
#   end
# end