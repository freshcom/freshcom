defmodule FCIdentity.AddUser do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :_type_, String.t(), default: "managed"
    field :user_id, String.t()
    field :status, String.t(), default: "active"
    field :username, String.t(), default: ""
    field :password, String.t(), default: ""
    field :email, String.t(), default: ""
    field :email_verified, String.t(), default: true

    field :first_name, String.t(), default: ""
    field :last_name, String.t(), default: ""
    field :name, String.t(), default: ""

    field :role, String.t()
  end

  @email_regex Application.get_env(:fc_identity, :email_regex)

  @valid_statuses ["pending", "active"]

  @valid_roles [
    "owner",
    "administrator",
    "developer",
    "manager",
    "marketing_specialist",
    "goods_specialist",
    "support_specialist",
    "read_only",
    "customer"
  ]

  @valid_types ["standard", "managed"]

  validates :account_id, presence: true, uuid: true

  validates :_type_, presence: true, inclusion: @valid_types
  validates :status, presence: true, inclusion: @valid_statuses
  validates :username, presence: true, length: [min: 3]
  validates :password, presence: true, length: [min: 8]
  validates :email, format: @email_regex

  validates :role, presence: true, inclusion: @valid_roles
end
