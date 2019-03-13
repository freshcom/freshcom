defmodule FCInventory.EntryCommitted do
  use FCBase, :event

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :request_id, String.t()
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()
    field :account_id, String.t()

    field :stock_id, String.t()
    field :transaction_id, String.t()
    field :serial_number, String.t()
    field :entry_id, String.t()

    field :status, String.t()
    field :quantity, Decimal.t()
    field :committed_at, DateTime.t()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.EntryCommitted do
  def decode(event) do
    %{event | quantity: Decimal.new(event.quantity)}
  end
end