defmodule FCInventory.TransactionUpdated do
  use FCBase, :event

  alias Decimal, as: D

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

    field :movement_id, String.t()
    field :line_item_id, String.t()
    field :transaction_id, String.t()

    field :destination_batch_id, String.t()
    field :quantity, Decimal.t()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.TransactionUpdated do
  def decode(event) do
    %{event | quantity: Decimal.new(event.quantity)}
  end
end