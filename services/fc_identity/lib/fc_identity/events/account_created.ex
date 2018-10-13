defmodule FCIdentity.AccountCreated do
  use TypedStruct

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :owner_id, String.t()
    field :mode, String.t()
    field :live_account_id, String.t()
    field :test_account_id, String.t()

    field :name, String.t()
    field :default_locale, String.t()
  end
end