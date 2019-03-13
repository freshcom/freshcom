defmodule FCInventory.ReservedStockDecreased do
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

    field :quantity, Decimal.t()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.ReservedStockDecreased do
  alias Decimal, as: D

  def decode(event) do
    %{event | quantity: D.new(event.quantity)}
  end
end