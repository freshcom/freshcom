defmodule FCIdentity.UserRegistrationRequested do
  use TypedStruct

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :user_id, String.t()

    field :username, String.t()
    field :password, String.t()
    field :email, String.t()
    field :is_term_accepted, boolean

    field :first_name, String.t()
    field :last_name, String.t()
    field :name, String.t()

    field :account_name, String.t()
    field :default_locale, String.t()
  end
end