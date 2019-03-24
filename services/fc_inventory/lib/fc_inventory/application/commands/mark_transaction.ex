defmodule FCInventory.MarkTransaction do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :request_id, String.t()
    field :account_id, String.t()
    field :client_id, String.t()
    field :staff_id, String.t()

    field :transaction_id, String.t()
    field :movement_id, String.t()

    field :status, String.t()
  end

  @valid_statuses ["zero_stock", "action_required"]

  validates :account_id, presence: true, uuid: true
  validates :staff_id, presence: true
  validates :status, presence: true, inclusion: @valid_statuses
end
