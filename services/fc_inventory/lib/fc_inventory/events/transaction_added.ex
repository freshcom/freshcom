defmodule FCInventory.TransactionAdded do
  use TypedStruct
  alias Decimal, as: D

  @derive Jason.Encoder
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
    field :batch_id, String.t()

    field :status, String.t()
    field :quantity, Decimal.t()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.TransactionAdded do
  alias FCInventory.Transaction

  def decode(event) do
    %{event | quantity: Decimal.new(event.quantity)}
  end
end