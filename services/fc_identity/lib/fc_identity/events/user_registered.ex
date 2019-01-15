defmodule FCIdentity.UserRegistered do
  use TypedStruct

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :request_id, String.t()
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()

    field :user_id, String.t()
    field :default_account_id, String.t()

    field :status, String.t(), default: "active"
    field :username, String.t()
    field :password_hash, String.t()
    field :email, String.t()
    field :is_term_accepted, boolean

    field :first_name, String.t()
    field :last_name, String.t()
    field :name, String.t()

    field :role, String.t()

    field :account_name, String.t()
    field :default_locale, String.t()
  end
end
