defmodule FCIdentity.UpdateUserInfo do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :effective_keys, [atom], default: []
    field :locale, String.t()

    field :user_id, String.t()

    field :username, String.t(), default: ""
    field :email, String.t(), default: ""

    field :first_name, String.t(), default: ""
    field :last_name, String.t(), default: ""
    field :name, String.t(), default: ""

    field :custom_data, map
  end

  @email_regex Application.get_env(:fc_identity, :email_regex)

  validates :user_id, presence: true, uuid: true

  validates :username, presence: true, length: [min: 3]
  validates :email, format: @email_regex
end
