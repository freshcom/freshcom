defmodule FCInventory.TransactionUpdated do
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

    field :effective_keys, [atom()]
    field :original_fields, map()
    field :locale, String.t()

    field :transaction_id, String.t()
    field :serial_number, String.t()
    field :quantity, String.t()

    field :name, String.t()
    field :number, String.t()
    field :label, String.t()
    field :expected_commit_date, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
    field :translations, map()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.TransactionUpdated do
  import FCSupport.Normalization

  def decode(event) do
    event = %{event | effective_keys: atomize_list(event.effective_keys)}

    if event.quantity do
      %{event | quantity: Decimal.new(event.quantity)}
    else
      event
    end
  end
end