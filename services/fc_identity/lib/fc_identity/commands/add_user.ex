defmodule FCIdentity.AddUser do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :user_id, String.t()
    field :status, String.t(), default: "active"
    field :username, String.t()
    field :password, String.t()
    field :email, String.t()
    field :email_verified, boolean(), default: true

    field :first_name, String.t()
    field :last_name, String.t()
    field :name, String.t()

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

  validates :account_id, presence: true, uuid: true

  validates :status, presence: true, inclusion: @valid_statuses
  validates :username, presence: true, length: [min: 3]
  validates :password, presence: true, length: [min: 8]
  validates :email, format: [with: @email_regex, allow_blank: true]

  validates :role, presence: true, inclusion: @valid_roles
end
