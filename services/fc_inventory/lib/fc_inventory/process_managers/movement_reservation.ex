defmodule FCInventory.MovementReservation do
  @moduledoc false
  use TypedStruct

  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:9403aad7-38f0-4fbd-a223-d024f212bdae",
    router: FCInventory.Router

  alias Decimal, as: D

  alias FCInventory.{
    ReserveStock,
    ProcessLineItem
  }

  alias FCInventory.{
    MovementCreated,
    StockReserved,
    StockPartiallyReserved,
    StockReservationFailed,
    MovementMarked,
    LineItemAdded,
    LineItemProcessed,
    LineItemUpdated
  }

  @derive Jason.Encoder

  typedstruct do
    field :requests, map(), default: %{}
  end

  def interested?(%MovementCreated{status: "pending", line_items: line_items} = event) when map_size(line_items) > 0, do: {:start, event.movement_id}

  def interested?(%LineItemProcessed{status: "reserving"} = event) do
    if D.cmp(event.quantity, D.new(0)) == :gt do
      {:continue, event.movement_id}
    else
      false
    end
  end

  def interested?(%LineItemAdded{status: "pending"} = event), do: {:start, event.movement_id}

  def interested?(%LineItemUpdated{effective_keys: ekeys} = event) do
    new_quantity = event.quantity
    old_quantity = event.original_fields[:quantity]

    if Enum.member?(ekeys, :quantity) && D.cmp(new_quantity, old_quantity) == :gt do
      {:start, event.movement_id}
    else
      false
    end
  end

  def interested?(%StockReserved{} = event), do: {:continue, event.movement_id}
  def interested?(%StockPartiallyReserved{} = event), do: {:continue, event.movement_id}
  def interested?(%StockReservationFailed{} = event), do: {:continue, event.movement_id}

  def interested?(%MovementMarked{original_status: "reserving"} = event), do: {:stop, event.movement_id}

  def interested?(_), do: false

  def handle(_, %MovementCreated{line_items: line_items} = event) do
    Enum.reduce(line_items, [], fn({stockable_id, line_item}, cmds) ->
      if line_item.status == "pending" do
        cmd = %ProcessLineItem{
          requester_role: "system",
          movement_id: event.movement_id,
          stockable_id: stockable_id,
          status: "reserving",
          quantity: line_item.quantity
        }
        cmds ++ [cmd]
      else
        cmds
      end
    end)
  end

  def handle(_, %LineItemAdded{status: "pending"} = event) do
    %ProcessLineItem{
      requester_role: "system",
      movement_id: event.movement_id,
      stockable_id: event.stockable_id,
      status: "reserving",
      quantity: event.quantity
    }
  end

  def handle(_, %LineItemUpdated{quantity: new_quantity} = event) do
    old_quantity = event.original_fields[:quantity]

    %ProcessLineItem{
      requester_role: "system",
      movement_id: event.movement_id,
      stockable_id: event.stockable_id,
      status: "reserving",
      quantity: D.sub(new_quantity, old_quantity)
    }
  end

  def handle(_, %LineItemProcessed{status: "reserving"} = event) do
    %ReserveStock{
      requester_role: "system",
      movement_id: event.movement_id,
      stockable_id: event.stockable_id,
      quantity: event.quantity
    }
  end

  def handle(_, %StockReserved{} = event) do
    [
      %ProcessLineItem{
        requester_role: "system",
        movement_id: event.movement_id,
        stockable_id: event.stockable_id,
        status: "reserving",
        quantity: D.sub(D.new(0), event.quantity)
      },
      %ProcessLineItem{
        requester_role: "system",
        movement_id: event.movement_id,
        stockable_id: event.stockable_id,
        status: "reserved",
        quantity: event.quantity
      }
    ]
  end

  def handle(_, %StockPartiallyReserved{} = event) do
    [
      %ProcessLineItem{
        requester_role: "system",
        movement_id: event.movement_id,
        stockable_id: event.stockable_id,
        status: "reserving",
        quantity: D.sub(D.new(0), event.quantity_requested)
      },
      %ProcessLineItem{
        requester_role: "system",
        movement_id: event.movement_id,
        stockable_id: event.stockable_id,
        status: "reserved",
        quantity: event.quantity_reserved
      }
    ]
  end

  def handle(_, %StockReservationFailed{} = event) do
    %ProcessLineItem{
      requester_role: "system",
      movement_id: event.movement_id,
      stockable_id: event.stockable_id,
      status: "reserving",
      quantity: D.sub(D.new(0), event.quantity)
    }
  end

  # def apply(state, %MovementCreated{line_items: line_items}) do
  #   requests =
  #     Enum.reduce(line_items, %{}, fn {stockable_id, line_item}, acc ->
  #       Map.put(acc, stockable_id, %{quantity: line_item.quantity})
  #     end)

  #   %{state | requests: requests}
  # end

  # def apply(%{requests: requests} = state, %LineItemAdded{} = event) do
  #   request = %{quantity: event.quantity}
  #   requests = Map.put(requests, event.stockable_id, request)

  #   %{state | requests: requests}
  # end

  # def apply(%{requests: requests} = state, %LineItemUpdated{quantity: new_quantity} = event) do
  #   old_quantity = event.original_fields[:quantity]
  #   quantity = D.sub(new_quantity, old_quantity)

  #   request = requests[event.stockable_id]
  #   request =
  #     if request do
  #       req_quantity = D.add(request.quantity, quantity)
  #       %{request | quantity: req_quantity}
  #     else
  #       %{quantity: quantity}
  #     end

  #   put_request(state, event.stockable_id, request)
  # end

  # def apply(state, %et{} = event) when et in [StockReserved, StockPartiallyReserved, StockReservationFailed] do
  #   remove_request(state, event.stockable_id)
  # end

  # defp put_request_status(%{requests: requests} = state, stockable_id, status) do
  #   request =
  #     requests
  #     |> Map.get(stockable_id)
  #     |> Map.put(:status, status)

  #   requests = Map.put(requests, stockable_id, request)

  #   %{state | requests: requests}
  # end

  # defp put_request(%{requests: requests} = state, stockable_id, request) do
  #   requests = Map.put(requests, stockable_id, request)
  #   %{state | requests: requests}
  # end

  # defp remove_request(%{requests: requests} = state, stockable_id) do
  #   requests = Map.drop(requests, [stockable_id])
  #   %{state | requests: requests}
  # end
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