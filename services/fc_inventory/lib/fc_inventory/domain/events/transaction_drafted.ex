defmodule FCInventory.TransactionDrafted do
  use FCBase, :event

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :staff_id, String.t()

    field :transaction_id, String.t()
    field :movement_id, String.t()
    field :cause_id, String.t()
    field :cause_type, String.t()

    field :sku_id, String.t()
    field :serial_number, String.t()
    field :source_id, String.t()
    field :destination_id, String.t()

    field :quantity, Decimal.t()
    field :expected_completion_date, DateTime.t()

    field :number, String.t()
    field :name, String.t()
    field :description, String.t()
    field :label, String.t()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.TransactionDrafted do
  def decode(event) do
    %{event | quantity: Decimal.new(event.quantity)}
  end
end