defmodule FCInventory.AddBatch do
  use TypedStruct
  use Vex.Struct

  typedstruct do
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

    field :status, String.t(), default: "active"
    field :number, String.t()
    field :label, String.t()
    field :quantity_on_hand, Decimal.t(), default: 0
    field :expires_at, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
  end

  @valid_statuses ["active", "disabled", "deleted"]

  validates :status, presence: true, inclusion: @valid_statuses
  validates :stockable_id, presence: true, uuid: true
  validates :storage_id, presence: true, uuid: true
end
