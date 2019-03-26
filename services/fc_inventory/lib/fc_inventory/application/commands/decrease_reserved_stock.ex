defmodule FCInventory.DecreaseReservedStock do
  use TypedStruct
  use Vex.Struct

  alias FCInventory.StockId
  alias FCInventory.{Account, Staff}

  typedstruct do
    field :request_id, String.t()
    field :account_id, String.t()
    field :staff_id, String.t()

    field :stock_id, StockId.t()
    field :transaction_id, String.t()

    field :quantity, Decimal.t()

    field :_account_, Account.t()
    field :_staff_, Staff.t()
  end

  validates :account_id, presence: true, uuid: true
  validates :staff_id, presence: true
  validates :stock_id, presence: true
  validates :quantity, presence: true
end
