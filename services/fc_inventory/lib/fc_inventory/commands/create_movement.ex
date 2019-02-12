defmodule FCInventory.CreateMovement do
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

    field :cause_id, String.t()
    field :cause_type, String.t()
    field :source_id, String.t()
    field :source_type, String.t()
    field :destination_id, String.t()
    field :destination_type, String.t()

    field :status, String.t(), default: "pending"
    field :number, String.t()
    field :label, String.t()
    field :expected_completion_date, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
  end

  @valid_statuses ["pending"]

  validates :status, presence: true, inclusion: @valid_statuses
  validates :destination_type, presence: [unless: [:source_type]]
end
