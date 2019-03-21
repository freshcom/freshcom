defmodule FCInventory.DecreaseReservedStock do
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

    field :quantity, Decimal.t()
  end

  validates :stock_id, presence: true
  validates :quantity, presence: true
end
