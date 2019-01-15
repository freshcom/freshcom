defmodule FCIdentity.ChangeDefaultAccount do
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
    field :user_id, String.t()
  end

  validates :user_id, presence: true, uuid: true
  validates :account_id, presence: true, uuid: true
end
