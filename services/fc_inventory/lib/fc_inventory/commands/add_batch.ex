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

    field :stockable_id, String.t()
    field :storage_id, String.t()

    field :status, String.t(), default: "active"
    field :quantity_on_hand, Decimal.t(), default: Decimal.new(0)
    field :expires_at, DateTime.t()

    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map(), default: %{}
  end

  @valid_statuses ["active"]

  validates :stockable_id, presence: true, uuid: true
  validates :storage_id, presence: true, uuid: true
  validates :status, presence: true, inclusion: @valid_statuses
end
