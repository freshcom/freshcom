defmodule FCInventory.DeleteEntry do
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
    field :entry_id, String.t()
  end

  validates :stock_id, presence: true
  validates :transaction_id, presence: true, uuid: true
  validates :entry_id, presence: true
end
