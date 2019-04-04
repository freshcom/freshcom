defmodule FCInventory.StockReservation do
  @moduledoc false
  use TypedStruct

  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:93d9d4b3-35ae-413e-8bc8-6b35c4121b0a",
    router: FCInventory.Router

  import Kernel, except: [apply: 2]

  alias Decimal, as: D
  alias FCInventory.{StockId, LineItem}
  alias FCInventory.{
    ReserveStock,
    DecreaseReservedStock,

    RecordStockReservation,
    FinishStockReservation
  }

  alias FCInventory.{
    StockReserved,
    StockPartiallyReserved,
    StockReservationFailed,
    ReservedStockDecreased,

    StockReservationRequested,
    StockReservationRecorded,
    StockReservationFinished
  }

  @derive Jason.Encoder
  typedstruct do
    field :requested, [LineItem.t()], default: []
    field :finished, [LineItem.t()], default: []
  end

  def interested?(%StockReservationRequested{} = event), do: {:start!, event.order_id}

  def interested?(%StockReserved{} = event), do: {:continue!, event.order_id}
  def interested?(%StockPartiallyReserved{} = event), do: {:continue!, event.order_id}
  def interested?(%StockReservationFailed{} = event), do: {:continue!, event.order_id}
  def interested?(%ReservedStockDecreased{} = event), do: {:continue!, event.order_id}

  def interested?(%StockReservationRecorded{} = event), do: {:continue!, event.order_id}

  def interested?(%StockReservationFinished{} = event), do: {:stop, event.order_id}
  def interested?(_), do: false

  def handle(_, %StockReservationRequested{} = event) do
    Enum.map(event.line_items, fn line_item ->
      case D.cmp(line_item.quantity_reserved, line_item.quantity) do
        :lt ->
          %ReserveStock{
            staff_id: "system",
            account_id: event.account_id,
            stock_id: %StockId{sku: line_item.sku, location_id: event.location_id},
            order_id: event.order_id,
            serial_number: line_item.serial_number,
            quantity: D.sub(line_item.quantity, line_item.quantity_reserved)
          }

        :gt ->
          %DecreaseReservedStock{
            staff_id: "system",
            account_id: event.account_id,
            stock_id: %StockId{sku: line_item.sku, location_id: event.location_id},
            order_id: event.order_id,
            quantity: D.sub(line_item.quantity_reserved, line_item.quantity)
          }

        _ ->
          nil
      end
    end)
  end

  def handle(_, %StockReserved{} = event) do
    %RecordStockReservation{
      account_id: event.account_id,
      staff_id: "system",
      order_id: event.order_id,
      sku: event.stock_id.sku,
      serial_number: event.serial_number,
      quantity: event.quantity
    }
  end

  def handle(_, %StockPartiallyReserved{} = event) do
    %RecordStockReservation{
      account_id: event.account_id,
      staff_id: "system",
      order_id: event.order_id,
      sku: event.stock_id.sku,
      serial_number: event.serial_number,
      quantity: event.quantity_reserved
    }
  end

  def handle(state, %StockReservationFailed{} = event) do
    attempt_finish(state, event)
  end

  def handle(state, %StockReservationRecorded{} = event) do
    attempt_finish(state, event)
  end

  def handle(_, %ReservedStockDecreased{} = event) do
    %RecordStockReservation{
      account_id: event.account_id,
      staff_id: "system",
      order_id: event.order_id,
      sku: event.stock_id.sku,
      serial_number: event.serial_number,
      quantity: D.minus(event.quantity)
    }
  end

  defp attempt_finish(state, event) do
    state = apply(state, event)

    if length(state.finished) == length(state.requested) do
      %FinishStockReservation{
        account_id: event.account_id,
        staff_id: "system",
        order_id: event.order_id
      }
    end
  end

  def apply(state, %StockReservationRequested{} = event) do
    %{state | requested: event.line_items}
  end

  def apply(state, %StockReservationFailed{} = event) do
    add_finished(state, event)
  end

  def apply(state, %StockReservationRecorded{} = event) do
    add_finished(state, event)
  end

  defp add_finished(state, event) do
    line_item = LineItem.get(state.requested, event.sku, event.serial_number)

    if line_item do
      %{state | finished: state.finished ++ [line_item]}
    else
      state
    end
  end

  def error({:error, {:continue!, :process_not_started}}, _, _) do
    :skip
  end

  defimpl Commanded.Serialization.JsonDecoder do
    def decode(event) do
      %{
        event
        | requested: LineItem.deserialize(event.requested),
          finished: LineItem.deserialize(event.finished)
      }
    end
  end
end
