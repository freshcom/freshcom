defmodule FCIdentity.PasswordChanged do
  use TypedStruct

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :user_id, String.t()
    field :new_password_hash, String.t()
  end
end