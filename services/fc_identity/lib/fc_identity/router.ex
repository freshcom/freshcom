defmodule FCIdentity.Router do
  @moduledoc false

  use Commanded.Commands.Router

  alias FCIdentity.{
    RegisterUser,
    FinishUserRegistration,
    AddUser,
    DeleteUser,
    GeneratePasswordResetToken,
    ChangePassword,
    ChangeUserRole,
    UpdateUserInfo,
    GenerateEmailVerificationToken,
    VerifyEmail
  }
  alias FCIdentity.{CreateAccount, UpdateAccountInfo}

  alias FCIdentity.{User, Account}
  alias FCIdentity.{UserHandler, AccountHandler}

  middleware FCBase.CommandValidation
  middleware FCBase.RequesterIdentification
  middleware FCBase.IdentifierGeneration

  identify User, by: :user_id, prefix: "user-"
  identify Account, by: :account_id, prefix: "account-"

  dispatch [
    RegisterUser,
    AddUser,
    FinishUserRegistration,
    DeleteUser,
    GeneratePasswordResetToken,
    ChangePassword,
    ChangeUserRole,
    UpdateUserInfo,
    GenerateEmailVerificationToken,
    VerifyEmail
  ], to: UserHandler, aggregate: User

  dispatch [CreateAccount, UpdateAccountInfo],
    to: AccountHandler, aggregate: Account
end