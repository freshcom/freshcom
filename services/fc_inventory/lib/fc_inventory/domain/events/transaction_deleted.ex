defmodule FCInventory.TransactionDeleted do
  use FCBase, :event

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :staff_id, String.t()

    field :transaction_id, String.t()
    field :movement_id, String.t()
    field :sku_id, String.t()
    field :source_id, String.t()
    field :destination_id, String.t()

    field :status, String.t()
    field :quantity, Decimal.t()
    field :quantity_prepared, Decimal.t()
  end

  defimpl Commanded.Serialization.JsonDecoder do
    def decode(event) do
      %{
        event
        | quantity: Decimal.new(event.quantity),
          quantity_prepared: Decimal.new(event.quantity_prepared)}
    end
  end
end
