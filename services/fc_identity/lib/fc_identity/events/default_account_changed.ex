defmodule FCIdentity.DefaultAccountChanged do
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
    field :original_default_account_id, String.t()
  end
end
