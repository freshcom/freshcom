defmodule FCIdentity.Router do
  @moduledoc false

  use Commanded.Commands.Router

  alias FCIdentity.{
    RegisterUser,
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
  alias FCIdentity.{AddApp}

  alias FCIdentity.{User, Account, App}
  alias FCIdentity.{UserHandler, AccountHandler, AppHandler}

  middleware(FCBase.CommandValidation)
  middleware(FCBase.RequesterIdentification)
  middleware(FCBase.IdentifierGeneration)

  identify(User, by: :user_id, prefix: "user-")
  identify(Account, by: :account_id, prefix: "account-")
  identify(App, by: :app_id, prefix: "app-")

  dispatch(
    [
      RegisterUser,
      AddUser,
      DeleteUser,
      GeneratePasswordResetToken,
      ChangePassword,
      ChangeUserRole,
      UpdateUserInfo,
      GenerateEmailVerificationToken,
      VerifyEmail
    ],
    to: UserHandler,
    aggregate: User
  )

  dispatch([CreateAccount, UpdateAccountInfo], to: AccountHandler, aggregate: Account)

  dispatch([AddApp], to: AppHandler, aggregate: App)
end
