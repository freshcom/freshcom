defmodule FCInventory.TransactionDrafted do
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

    field :transaction_id, String.t()
    field :movement_id, String.t()
    field :cause_id, String.t()
    field :cause_type, String.t()
    field :stockable_id, String.t()
    field :source_id, String.t()
    field :destination_id, String.t()

    field :quantity, Decimal.t()
    field :serial_number, String.t()
    field :expected_completion_date, DateTime.t()

    field :name, String.t()
    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map(), default: %{}
    field :translations, map(), default: %{}
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.TransactionDrafted do
  def decode(event) do
    %{event | quantity: Decimal.new(event.quantity)}
  end
end