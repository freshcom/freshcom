defmodule FCInventory.OrderItemProcessed do
  use FCBase, :event

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :staff_id, String.t()

    field :order_id, String.t()
    field :sku, String.t()
    field :serial_number, String.t()
    field :quantity, Decimal.t()
  end
end
