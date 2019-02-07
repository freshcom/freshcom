defmodule FCInventory.CreateTransaction do
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
    field :source_id, String.t()
    field :source_type, String.t()
    field :destination_id, String.t()
    field :destination_type, String.t()

    field :status, String.t(), default: "pending"
    field :number, String.t()
    field :quantity, Decimal.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
  end

  @valid_statuses ["pending", "ready", "committed", "deleted"]

  validates :status, presence: true, inclusion: @valid_statuses
  validates :quantity, presence: true, number: [greater_than: 0]
  validates :stockable_id, presence: true, uuid: true
  validates :destination_type, presence: [unless: [:source_type]]
end
