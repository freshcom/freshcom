defmodule FCInventory.MarkTransaction do
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

    field :transaction_id, String.t()
    field :movement_id, String.t()

    field :status, String.t()
  end

  @valid_statuses ["zero_stock", "action_required"]

  validates :status, presence: true, inclusion: @valid_statuses
end
