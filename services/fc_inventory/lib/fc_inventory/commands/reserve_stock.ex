defmodule FCInventory.ReserveStock do
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

    field :stock_id, String.t()
    field :transaction_id, String.t()
    field :serial_number, String.t()

    field :quantity, Decimal.t()
    field :expected_commit_date, DateTime.t()
  end

  validates :stock_id, presence: true
  validates :quantity, presence: true
end
