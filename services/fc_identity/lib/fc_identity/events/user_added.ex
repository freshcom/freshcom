defmodule FCIdentity.UserAdded do
  use TypedStruct

  @derive Jason.Encoder
  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :request_id, String.t()
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()
    field :account_id, String.t()

    field :user_id, String.t()
    field :type, String.t()
    field :status, String.t(), status: "active"
    field :username, String.t()
    field :password_hash, String.t()
    field :email, String.t()
    field :email_verified, boolean(), default: false

    field :first_name, String.t()
    field :last_name, String.t()
    field :name, String.t()

    field :role, String.t()

    field :custom_data, map(), default: %{}
    field :translations, map(), default: %{}
  end
end
