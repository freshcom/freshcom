defmodule FCIdentity.AppAdded do
  use TypedStruct

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :app_id, String.t()
    field :status, String.t()
    field :type, String.t()
    field :name, String.t()
  end
end