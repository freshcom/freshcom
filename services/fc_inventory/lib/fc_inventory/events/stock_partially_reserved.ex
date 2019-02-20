defmodule FCInventory.StockPartiallyReserved do
  use TypedStruct

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

    field :stockable_id, String.t()
    field :line_item_id, String.t()
    field :movement_id, String.t()

    field :quantity_target, Decimal.t()
    field :quantity_reserved, Decimal.t()
    field :transactions, [FCInventory.Transaction.t()]
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.StockPartiallyReserved do
  alias FCInventory.Transaction
  alias Decimal, as: D

  def decode(event) do
    transactions =
      Enum.reduce(event.transactions, %{}, fn({id, data}, transactions) ->
        Map.put(transactions, id, Transaction.deserialize(data))
      end)

    %{
      event
      | transactions: transactions,
        quantity_target: D.new(event.quantity_target),
        quantity_reserved: D.new(event.quantity_reserved)
    }
  end
end