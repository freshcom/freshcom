defmodule FCIdentity.ChangeUserRole do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :user_id, String.t()
    field :role, String.t()
  end

  @valid_roles [
    "administrator",
    "developer",
    "manager",
    "marketing_specialist",
    "goods_specialist",
    "support_specialist",
    "read_only",
    "customer"
  ]

  validates :account_id, presence: true, uuid: true
  validates :user_id, presence: true, uuid: true
  validates :role, presence: true, inclusion: @valid_roles
end
