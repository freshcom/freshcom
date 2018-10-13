defmodule FCIdentity.GeneratePasswordResetToken do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :user_id, String.t()
    field :expires_at, DateTime.t()
  end

  validates :user_id, presence: true, uuid: true
  validates :expires_at, presence: true
end
