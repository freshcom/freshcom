defmodule FCIdentity.CloseAccount do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :request_id, String.t()
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()

    field :account_id, String.t()
  end

  validates :account_id, presence: true, uuid: true
end
