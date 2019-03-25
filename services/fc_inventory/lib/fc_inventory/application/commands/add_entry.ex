defmodule FCInventory.AddEntry do
  use TypedStruct
  use Vex.Struct

  alias FCInventory.{Account, Staff}

  typedstruct do
    field :request_id, String.t()
    field :account_id, String.t()
    field :staff_id, String.t()

    field :stock_id, String.t()
    field :transaction_id, String.t()
    field :serial_number, String.t()
    field :entry_id, String.t()

    field :status, String.t(), default: "planned"
    field :quantity, Decimal.t()
    field :expected_commit_date, DateTime.t()

    field :_account_, Account.t()
    field :_staff_, Staff.t()
  end

  validates :account_id, presence: true, uuid: true
  validates :staff_id, presence: true
  validates :stock_id, presence: true
  validates :transaction_id, presence: true, uuid: true

  validates :quantity, presence: true
end
