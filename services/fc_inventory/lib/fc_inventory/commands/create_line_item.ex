defmodule FCInventory.CreateLineItem do
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

    field :movement_id, String.t()
    field :stockable_id, String.t()
    field :cause_id, String.t()
    field :cause_type, String.t()
    field :quantity, Decimal.t()
    field :quantity_processed, Decimal.t(), default: Decimal.new(0)

    field :name, String.t()
    field :status, String.t(), default: "pending"
    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
  end

  @valid_statuses ["pending"]

  validates :movement_id, presence: true, uuid: true
  validates :stockable_id, presence: true, uuid: true
  validates :status, presence: true, inclusion: @valid_statuses
  validates :quantity, presence: true
end
