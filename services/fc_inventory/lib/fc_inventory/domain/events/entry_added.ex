defmodule FCInventory.EntryAdded do
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

    field :status, String.t()
    field :quantity, Decimal.t()
    field :expected_commit_date, DateTime.t()
  end

  defimpl Commanded.Serialization.JsonDecoder do
    def decode(event) do
      %{
        event
        | stock_id: StockId.from(event.stock_id),
          quantity: Decimal.new(event.quantity)
      }
    end
  end
end

