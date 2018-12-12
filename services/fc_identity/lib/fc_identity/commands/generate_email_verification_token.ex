defmodule FCIdentity.GenerateEmailVerificationToken do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()
    field :account_id, String.t()

    field :user_id, String.t()
    field :expires_at, DateTime.t()
  end

  validates :user_id, presence: true, uuid: true
  validates :expires_at, presence: true
end
