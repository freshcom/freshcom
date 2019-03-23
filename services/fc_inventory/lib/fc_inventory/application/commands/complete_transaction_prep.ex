defmodule FCInventory.CompleteTransactionPrep do
  use TypedStruct
  use Vex.Struct

  alias FCInventory.{Account, Staff}

  typedstruct do
    field :request_id, String.t()
    field :account_id, String.t()
    field :client_id, String.t()
    field :staff_id, String.t()

    field :transaction_id, String.t()
    field :quantity, Decimal.t(), default: Decimal.new(0)

    field :_account_, Account.t()
    field :_staff_, Staff.t()
  end

  validates :account_id, presence: true, uuid: true
  validates :staff_id, presence: true
  validates :transaction_id, presence: true, uuid: true
end
