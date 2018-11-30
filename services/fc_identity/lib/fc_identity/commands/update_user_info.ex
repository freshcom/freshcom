defmodule FCIdentity.UpdateUserInfo do
  use TypedStruct
  use Vex.Struct

  alias FCIdentity.CommandValidator

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :effective_keys, [String.t()], default: []
    field :locale, String.t()

    field :user_id, String.t()

    field :username, String.t()
    field :email, String.t()

    field :first_name, String.t()
    field :last_name, String.t()
    field :name, String.t()

    field :custom_data, map
  end

  validates :user_id, presence: true, uuid: true

  validates :username, presence: true, by: &CommandValidator.username/2
  validates :email, by: &CommandValidator.email/2
end
