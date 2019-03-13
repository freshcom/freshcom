defmodule FCInventory.UpdateTransaction do
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

    field :effective_keys, [String.t()], default: []
    field :locale, String.t()

    field :transaction_id, String.t()
    field :serial_number, String.t()
    field :quantity, String.t()

    field :name, String.t()
    field :number, String.t()
    field :label, String.t()
    field :expected_commit_date, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
  end

  validates :transaction_id, presence: true, uuid: true
end
