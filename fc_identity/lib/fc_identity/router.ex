defmodule FCIdentity.Router do
  use Commanded.Commands.Router

  alias FCIdentity.{
    RegisterUser,
    FinishUserRegistration,
    AddUser,
    DeleteUser,
    GeneratePasswordResetToken,
    ChangePassword,
    ChangeUserRole,
    UpdateUserInfo
  }
  alias FCIdentity.{CreateAccount, UpdateAccountInfo}

  alias FCIdentity.{User, Account}
  alias FCIdentity.{UserHandler, AccountHandler}

  middleware FCIdentity.CommandValidation
  middleware FCIdentity.RequesterIdentification
  middleware FCIdentity.IdentifierGeneration

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
    UpdateUserInfo
  ], to: UserHandler, aggregate: User

  dispatch [CreateAccount, UpdateAccountInfo],
    to: AccountHandler, aggregate: Account
end