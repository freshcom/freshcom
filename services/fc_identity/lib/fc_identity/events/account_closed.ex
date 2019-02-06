defmodule FCIdentity.AccountClosed do
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
    field :test_account_id, String.t()
    field :owner_id, String.t()
    field :mode, String.t()
    field :handle, String.t()
  end
end
