defmodule FCIdentity.VerifyEmail do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :user_id, String.t()
    field :verification_token, String.t()
  end

  validates :user_id, presence: true, uuid: true
  validates :verification_token, presence: [unless: :requester_id]
end
