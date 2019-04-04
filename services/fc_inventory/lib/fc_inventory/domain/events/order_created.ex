defmodule FCInventory.OrderCreated do
  use FCBase, :event

  alias FCInventory.LineItem

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :staff_id, String.t()

    field :order_id, String.t()
    field :location_id, String.t()
    field :status, String.t()
    field :line_items, [LineItem.t()]

    field :name, String.t()
    field :email, String.t()
    field :phone_number, String.t()

    field :shipping_address_line_one, String.t()
    field :shipping_address_line_two, String.t()
    field :shipping_address_city, String.t()
    field :shipping_address_province, String.t()
    field :shipping_address_country_code, String.t()
    field :shipping_address_postal_code, String.t()
  end

  defimpl Commanded.Serialization.JsonDecoder do
    def decode(event) do
      %{event | line_items: LineItem.deserialize(event.line_items)}
    end
  end
end
