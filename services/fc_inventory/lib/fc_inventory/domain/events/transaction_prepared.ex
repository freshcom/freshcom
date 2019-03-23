defmodule FCInventory.TransactionPrepared do
  use FCBase, :event

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :client_id, String.t()
    field :staff_id, String.t()

    field :transaction_id, String.t()
    field :movement_id, String.t()

    field :status, String.t()
    field :quantity, Decimal.t()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.TransactionPrepared do
  def decode(event) do
    %{event | quantity: Decimal.new(event.quantity)}
  end
end