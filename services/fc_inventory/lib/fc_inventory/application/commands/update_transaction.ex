defmodule FCInventory.UpdateTransaction do
  use TypedStruct
  use Vex.Struct

  alias FCInventory.{Account, Staff}

  typedstruct do
    field :request_id, String.t()
    field :account_id, String.t()
    field :staff_id, String.t()

    field :effective_keys, [atom], default: []
    field :transaction_id, String.t()

    field :quantity, Decimal.t()
    field :expected_commit_date, DateTime.t()

    field :summary, String.t()
    field :description, String.t()
    field :label, String.t()

    field :_account_, Account.t()
    field :_staff_, Staff.t()
  end

  validates :account_id, presence: true, uuid: true
  validates :staff_id, presence: true
  validates :transaction_id, presence: true, uuid: true
end
