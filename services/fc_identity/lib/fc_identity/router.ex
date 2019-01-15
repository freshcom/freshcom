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
    ChangeDefaultAccount,
    GenerateEmailVerificationToken,
    VerifyEmail
  }

  alias FCIdentity.{CreateAccount, UpdateAccountInfo, ChangeAccountSystemLabel, CloseAccount}
  alias FCIdentity.{AddApp, UpdateApp, DeleteApp}

  alias FCIdentity.{User, Account, App}
  alias FCIdentity.{UserHandler, AccountHandler, AppHandler}

  middleware(FCBase.CommandValidation)
  middleware(FCBase.RequesterIdentification)
  middleware(FCBase.ClientIdentification)
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
      ChangeDefaultAccount,
      GenerateEmailVerificationToken,
      VerifyEmail
    ],
    to: UserHandler,
    aggregate: User
  )

  dispatch([CreateAccount, UpdateAccountInfo, ChangeAccountSystemLabel, CloseAccount],
    to: AccountHandler,
    aggregate: Account
  )

  dispatch([AddApp, UpdateApp, DeleteApp], to: AppHandler, aggregate: App)
end
