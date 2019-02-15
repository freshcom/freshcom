defmodule FCInventory.BatchAdded do
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

    field :batch_id, String.t()
    field :stockable_id, String.t()
    field :storage_id, String.t()

    field :status, String.t()
    field :number, String.t()
    field :label, String.t()
    field :quantity_on_hand, Decimal.t()
    field :expires_at, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map(), default: %{}
    field :translations, map(), default: %{}
  end
end
