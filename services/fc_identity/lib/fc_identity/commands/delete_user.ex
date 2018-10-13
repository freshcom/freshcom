defmodule FCIdentity.DeleteUser do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :user_id, String.t()
  end

  validates :account_id, presence: true, uuid: true
  validates :user_id, presence: true, uuid: true
end
