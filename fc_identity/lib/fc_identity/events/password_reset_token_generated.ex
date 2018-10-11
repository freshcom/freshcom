defmodule FCIdentity.PasswordResetTokenGenerated do
  use TypedStruct

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :user_id, String.t()
    field :token, String.t()
    field :expires_at, String.t()
  end
end