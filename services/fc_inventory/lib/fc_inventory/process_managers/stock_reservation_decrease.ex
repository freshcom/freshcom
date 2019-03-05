defmodule FCInventory.StockReservationDecrease do
  @moduledoc false
  use TypedStruct

  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:7d3bd3b7-5bd1-4696-9f2f-8fd6f7a2423a",
    router: FCInventory.Router

  alias Decimal, as: D
  alias FCInventory.LineItem

  alias FCInventory.{
    DecreaseStockReservation,
    ProcessLineItem
  }

  alias FCInventory.{
    StockReservationDecreased,
    LineItemUpdated,
    LineItemProcessed
  }

  @derive Jason.Encoder
  defstruct []

  def interested?(%LineItemUpdated{effective_keys: ekeys} = event) do
    new_quantity = event.quantity
    old_quantity = event.original_fields[:quantity]

    if Enum.member?(ekeys, :quantity) && D.cmp(new_quantity, old_quantity) == :lt do
      {:start, event.movement_id}
    else
      false
    end
  end

  def interested?(%LineItemProcessed{status: "decreasing_reservation"} = event) do
    if D.cmp(event.quantity, D.new(0)) == :gt do
      {:continue, event.movement_id}
    else
      false
    end
  end
  def interested?(%StockReservationDecreased{} = event), do: {:continue, event.movement_id}

  def interested?(%LineItemProcessed{status: "reserved"} = event) do
    if D.cmp(event.quantity, D.new(0)) == :lt do
      {:stop, event.movement_id}
    else
      false
    end
  end

  def interested?(_), do: false

  def handle(_, %LineItemUpdated{quantity: new_quantity} = event) do
    old_quantity = event.original_fields[:quantity]

    %ProcessLineItem{
      requester_role: "system",
      movement_id: event.movement_id,
      stockable_id: event.stockable_id,
      status: "decreasing_reservation",
      quantity: D.sub(old_quantity, new_quantity)
    }
  end

  def handle(_, %LineItemProcessed{status: "decreasing_reservation"} = event) do
    %DecreaseStockReservation{
      requester_role: "system",
      movement_id: event.movement_id,
      stockable_id: event.stockable_id,
      quantity: event.quantity
    }
  end

  def handle(_, %StockReservationDecreased{} = event) do
    [
      %ProcessLineItem{
        requester_role: "system",
        movement_id: event.movement_id,
        stockable_id: event.stockable_id,
        status: "decreasing_reservation",
        quantity: D.sub(D.new(0), event.quantity)
      },
      %ProcessLineItem{
        requester_role: "system",
        movement_id: event.movement_id,
        stockable_id: event.stockable_id,
        status: "reserved",
        quantity: D.sub(D.new(0), event.quantity)
      }
    ]
  end
end
