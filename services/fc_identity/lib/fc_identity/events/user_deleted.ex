defmodule FCIdentity.UserDeleted do
  use TypedStruct

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :user_id, String.t()
  end
end