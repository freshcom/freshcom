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

    field :movement_id, String.t()
    field :cause_id, String.t()
    field :cause_type, String.t()
    field :source_id, String.t()
    field :destination_id, String.t()

    field :expected_commit_date, DateTime.t()

    field :name, String.t()
    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map(), default: %{}
  end

  validates :source_id, presence: true
  validates :destination_id, presence: true
end
