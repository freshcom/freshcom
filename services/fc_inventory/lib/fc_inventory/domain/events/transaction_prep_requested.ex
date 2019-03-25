defmodule FCInventory.TransactionPrepRequested do
  use FCBase, :event

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :staff_id, String.t()

    field :transaction_id, String.t()
    field :sku_id, String.t()
    field :serial_number, String.t()
    field :source_id, String.t()
    field :destination_id, String.t()

    field :quantity, Decimal.t()
    field :quantity_prepared, Decimal.t()
    field :expected_completion_date, DateTime.t()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.TransactionPrepRequested do
  def decode(event) do
    %{
      event
      | quantity: Decimal.new(event.quantity),
        quantity_prepared: Decimal.new(event.quantity_prepared)
    }
  end
end