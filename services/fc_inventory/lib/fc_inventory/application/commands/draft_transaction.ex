defmodule FCInventory.DraftTransaction do
  use TypedStruct
  use Vex.Struct

  alias FCInventory.{Account, Staff}

  typedstruct do
    field :request_id, String.t()
    field :account_id, String.t()
    field :staff_id, String.t()

    field :transaction_id, String.t()
    field :movement_id, String.t()
    field :cause_id, String.t()
    field :cause_type, String.t()

    field :sku_id, String.t()
    field :serial_number, String.t()
    field :source_id, String.t()
    field :destination_id, String.t()

    field :quantity, Decimal.t(), default: Decimal.new(0)
    field :expected_completion_date, DateTime.t()

    field :number, String.t()
    field :name, String.t()
    field :description, String.t()
    field :label, String.t()

    field :_account_, Account.t()
    field :_staff_, Staff.t()
  end

  validates :account_id, presence: true, uuid: true
  validates :staff_id, presence: true
  validates :sku_id, presence: true, uuid: true
  validates :source_id, presence: true, uuid: true
  validates :destination_id, presence: true, uuid: true
end
