defmodule FCInventory.BatchReserved do
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
    field :batch_id, String.t()

    field :status, String.t()
    field :quantity, Decimal.t()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.BatchReserved do
  def decode(event) do
    %{event | quantity: Decimal.new(event.quantity)}
  end
end