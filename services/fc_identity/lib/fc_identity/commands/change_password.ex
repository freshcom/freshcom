defmodule FCIdentity.ChangePassword do
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
    field :reset_token, String.t()
    field :current_password, String.t()

    field :new_password, String.t()
  end

  validates :user_id, presence: true, uuid: true
  validates :reset_token , presence: [unless: :requester_id]
  validates :current_password, presence: [if: &__MODULE__.changing_own_password?/1]

  validates :new_password, presence: true, length: [min: 8]

  def changing_own_password?(%{requester_id: rid, user_id: uid}) when not is_nil(rid) and not is_nil(uid) do
    rid == uid
  end

  def changing_own_password?(_), do: false
end
