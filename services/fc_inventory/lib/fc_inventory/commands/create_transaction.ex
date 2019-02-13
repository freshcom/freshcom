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

    field :line_item_id, String.t()
    field :source_stockable_id, String.t()
    field :source_id, String.t()
    field :source_type, String.t()
    field :destination_stockable_id, String.t()
    field :destination_id, String.t()
    field :destination_type, String.t()

    field :status, String.t(), default: "pending"
    field :number, String.t()
    field :quantity, Decimal.t()
    field :quantity_processed, Decimal.t(), default: Decimal.new(0)
    field :expected_completion_date, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
  end

  @valid_statuses ["pending", "ready", "committed", "deleted"]

  validates :status, presence: true, inclusion: @valid_statuses
  validates :quantity, presence: true
  validates :destination_stockable_id, presence: [unless: [:source_stockable_id]]
  validates :destination_type, presence: [unless: [:source_type]]
end
