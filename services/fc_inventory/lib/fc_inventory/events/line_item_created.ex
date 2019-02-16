defmodule FCInventory.LineItemCreated do
  use TypedStruct
  alias Decimal, as: D

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

    field :line_item_id, String.t()

    field :movement_id, String.t()
    field :stockable_id, String.t()
    field :cause_id, String.t()
    field :cause_type, String.t()
    field :quantity, Decimal.t()

    field :name, String.t()
    field :status, String.t()
    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map(), default: %{}
    field :translations, map(), default: %{}
  end

  def deserialize(event) do
    event
    |> Map.put(:quantity, D.new(event.quantity))
  end
end
