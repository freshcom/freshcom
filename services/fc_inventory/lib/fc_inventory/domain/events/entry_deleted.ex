defmodule FCInventory.EntryDeleted do
  use FCBase, :event

  alias FCInventory.StockId

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :staff_id, String.t()

    field :stock_id, StockId.t()
    field :transaction_id, String.t()
    field :serial_number, String.t()
    field :entry_id, String.t()

    field :quantity, Decimal.t()
  end

  defimpl Commanded.Serialization.JsonDecoder do
    def decode(event) do
      event =
        if event.quantity do
          %{event | quantity: Decimal.new(event.quantity)}
        else
          event
        end

      %{event | stock_id: StockId.from(event.stock_id)}
    end
  end
end
