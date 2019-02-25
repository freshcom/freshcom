defmodule FCInventory.LineItemProcessed do
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

    field :movement_id, String.t()
    field :stockable_id, String.t()

    field :status, String.t()
    field :quantity, Decimal.t()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.LineItemProcessed do
  def decode(event) do
    if event.quantity do
      %{event | quantity: Decimal.new(event.quantity)}
    else
      event
    end
  end
end