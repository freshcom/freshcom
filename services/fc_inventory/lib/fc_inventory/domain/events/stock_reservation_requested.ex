defmodule FCInventory.StockReservationRequested do
  use FCBase, :event

  alias FCInventory.LineItem

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :staff_id, String.t()

    field :order_id, String.t()
    field :location_id, String.t()
    field :line_items, [LineItem.t()]
  end

  defimpl Commanded.Serialization.JsonDecoder do
    def decode(event) do
      %{event | line_items: LineItem.deserialize(event.line_items)}
    end
  end
end
