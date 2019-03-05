defmodule FCInventory.StockPartiallyReserved do
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

    field :stockable_id, String.t()
    field :movement_id, String.t()

    field :quantity_requested, Decimal.t()
    field :quantity_reserved, Decimal.t()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.StockPartiallyReserved do
  alias Decimal, as: D

  def decode(event) do
    %{
      event
      | quantity_requested: D.new(event.quantity_requested),
        quantity_reserved: D.new(event.quantity_reserved)
    }
  end
end