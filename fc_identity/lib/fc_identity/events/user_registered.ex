defmodule FCIdentity.UserRegistered do
  use TypedStruct

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :user_id, String.t()
    field :default_account_id, String.t()

    field :username, String.t()
    field :password_hash, String.t()
    field :email, String.t()
    field :is_term_accepted, boolean

    field :first_name, String.t()
    field :last_name, String.t()
    field :name, String.t()
  end
end