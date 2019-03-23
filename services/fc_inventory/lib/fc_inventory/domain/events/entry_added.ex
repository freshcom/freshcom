defmodule FCInventory.EntryAdded do
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

    field :status, String.t()
    field :quantity, Decimal.t()
    field :expected_commit_date, DateTime.t()

    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map(), default: %{}
    field :translations, map(), default: %{}
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

