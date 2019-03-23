defmodule FCInventory.EntryDeleted do
  use FCBase, :event

  alias FCInventory.StockId

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
