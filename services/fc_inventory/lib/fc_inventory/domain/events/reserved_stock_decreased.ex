defmodule FCInventory.ReservedStockDecreased do
  use FCBase, :event

  alias FCInventory.StockId

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :staff_id, String.t()

    field :stock_id, StockId.t()
    field :transaction_id, String.t()

    field :quantity, Decimal.t()
  end

  defimpl Commanded.Serialization.JsonDecoder do
    alias Decimal, as: D

    def decode(event) do
      %{
        event
        | stock_id: StockId.from(event.stock_id),
          quantity: Decimal.new(event.quantity)
      }
    end
  end
end