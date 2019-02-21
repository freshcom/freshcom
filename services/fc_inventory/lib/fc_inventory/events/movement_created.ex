defmodule FCInventory.MovementCreated do
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

    field :cause_id, String.t()
    field :cause_type, String.t()
    field :source_id, String.t()
    field :source_type, String.t()
    field :destination_id, String.t()
    field :destination_type, String.t()

    field :status, String.t()
    field :line_items, map(), default: %{}
    field :expected_completion_date, DateTime.t()

    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map(), default: %{}
    field :translations, map(), default: %{}
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.MovementCreated do
  alias FCInventory.LineItem

  def decode(event) do
    line_items =
      Enum.reduce(event.line_items, %{}, fn({id, data}, line_items) ->
        Map.put(line_items, id, LineItem.deserialize(data))
      end)

    %{event | line_items: line_items}
  end
end