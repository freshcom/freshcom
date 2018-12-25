defmodule Freshcom.Identity do
  @moduledoc """
  This API module provides functions that deal with identity and access management.
  It follows a combination of Stripe and AWS style IAM.

  Generally speaking, identity in Freshcom consist of three things:
  - The user that is making the request (the requester)
  - The app that is making the request on behalf of the user (the client)
  - The account that the request is targeting

  These three resources are used together to authenticate and authorize each request,
  and this module provides functions to help you create and manage these three resources.
  """

  import FCSupport.Normalization, only: [atomize_keys: 2]
  import Freshcom.Context
  import Freshcom.IdentityPolicy
  import UUID

  use OK.Pipe

  alias Freshcom.{Context, Request}
  alias FCIdentity.{
    RegisterUser,
    AddUser,
    UpdateUserInfo,
    ChangeDefaultAccount,
    ChangeUserRole,
    ChangePassword,
    DeleteUser,
    CreateAccount,
    UpdateAccountInfo,
    CloseAccount,
    GeneratePasswordResetToken,
    AddApp,
    UpdateApp,
    DeleteApp
  }
  alias FCIdentity.{
    UserRegistered,
    UserAdded,
    UserInfoUpdated,
    DefaultAccountChanged,
    UserRoleChanged,
    PasswordChanged,
    UserDeleted,
    AccountCreated,
    AccountInfoUpdated,
    AccountClosed,
    PasswordResetTokenGenerated,
    AppAdded,
    AppUpdated,
    AppDeleted
  }
  alias Freshcom.{Repo, Projector}
  alias Freshcom.{UserProjector, AccountProjector, AppProjector}
  alias Freshcom.{User, Account, RefreshToken, App}

  @doc """
  Register a standard user.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.register_user(%Request{
    client_id: app_id,
    fields: %{
      "name" => "Demo User",
      "username" => "test@example.com",
      "email" => "test@example.com",
      "password" => "test1234",
      "account_name" => "Unamed Account",
      "default_locale" => "en",
      "is_term_accepted" => true
    }
  })
  ```

  ## Field Validations

  `username` _(required)_
  - Must be unique across all standard user
  - Length between 3 and 120 characters
  - Can contain alphanumeric characters and `'`, `.`, `+`, `-`, `@`

  `password` _(required)_
  - Length must be greater than 8 characters

  `is_term_accepted` _(required)_
  - Must be true

  `email`
  - Must be in correct format

  `account_name`
  - Default is `"Unamed Account"`

  `default_locale`
  - Default is `"en"`
  """
  @spec register_user(Request.t()) :: Context.resp()
  def register_user(%Request{} = req) do
    req
    |> to_command(%RegisterUser{})
    |> dispatch_and_wait(UserRegistered)
    ~> Map.get(:user)
    ~> preload(req)
    |> to_response()
  end

  @doc """
  Add a managed user to an account.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.add_user(%Request{
    requester_id: user_id,
    client_id: app_id,
    account_id: account_id,
    fields: %{
      "username" => "testuser",
      "password" => "test1234",
      "role" => "developer",
      "email" => "test@example.com",
      "name" => "Demo User"
    }
  })
  ```

  ## Field Validations

  `username` _(required)_
  - Must be unique across all managed user of the same account
  - Length between 3 and 120 characters
  - Can contain alphanumeric characters and `'`, `.`, `+`, `-`, `@`

  `password` _(required)_
  - Length must be greater than 8 characters

  `role` _(required)_
  - Please see `Freshcom.User` for list of valid roles

  `email`
  - Must be in correct format

  `name`
  - Length must be between 2 to 255

  ## Authorization

  Only user with role `"owner"` and `"administrator"` can add a user.
  """
  @spec add_user(Request.t()) :: Context.resp()
  def add_user(%Request{} = req) do
    req
    |> to_command(%AddUser{})
    |> dispatch_and_wait(UserAdded)
    ~> Map.get(:user)
    ~> preload(req)
    |> to_response()
  end

  @doc """
  Update a user's general information.
  """
  @spec update_user_info(Request.t()) :: Context.resp()
  def update_user_info(%Request{} = req) do
    identifiers = atomize_keys(req.identifiers, ["id"])

    req
    |> to_command(%UpdateUserInfo{})
    |> Map.put(:user_id, identifiers[:id])
    |> dispatch_and_wait(UserInfoUpdated)
    ~> Map.get(:user)
    ~> preload(req)
    |> to_response()
  end

  @doc """
  Change the default account of a standard user.
  """
  @spec change_default_account(Request.t()) :: Context.resp()
  def change_default_account(%Request{} = req) do
    req
    |> to_command(%ChangeDefaultAccount{})
    |> Map.put(:user_id, req.requester_id)
    |> Map.put(:account_id, req.fields["id"])
    |> dispatch_and_wait(DefaultAccountChanged)
    ~> Map.get(:user)
    ~> preload(req)
    |> to_response()
  end

  @doc """
  Change the role of a managed user.
  """
  @spec change_user_role(Request.t()) :: Context.resp()
  def change_user_role(%Request{} = req) do
    cmd = %ChangeUserRole{
      user_id: req.identifiers["id"],
      role: req.fields["value"]
    }

    req
    |> to_command(cmd)
    |> dispatch_and_wait(UserRoleChanged)
    ~> Map.get(:user)
    ~> preload(req)
    |> to_response()
  end

  @doc """
  Generate a password reset token for a user.
  """
  @spec generate_password_reset_token(Request.t()) :: Context.resp()
  def generate_password_reset_token(%Request{identifiers: %{"username" => username}} = req) do
    user =
      req
      |> Map.put(:identifiers, %{"username" => username})
      |> to_query(User)
      |> Repo.one()

    req
    |> to_command(%GeneratePasswordResetToken{
        user_id: (user || %{id: uuid4()}).id,
        expires_at: Timex.shift(Timex.now(), hours: 24)
      })
    |> dispatch_and_wait(PasswordResetTokenGenerated)
    ~> Map.get(:user)
    |> to_response()
  end

  @doc """
  Generate a password reset token.
  """
  def generate_password_reset_token(%Request{identifiers: %{"id" => id}} = req) do
    req
    |> to_command(%GeneratePasswordResetToken{
        user_id: id,
        expires_at: Timex.shift(Timex.now(), hours: 24)
      })
    |> dispatch_and_wait(PasswordResetTokenGenerated)
    ~> Map.get(:user)
    |> to_response()
  end

  def generate_password_reset_token(_), do: {:error, :not_found}

  @doc """
  Change the password of a user.
  """
  @spec change_password(Request.t()) :: Context.resp()
  def change_password(%Request{identifiers: %{"id" => id}} = req) do
    req
    |> to_command(%ChangePassword{})
    |> Map.put(:user_id, id)
    |> dispatch_and_wait(PasswordChanged)
    ~> Map.get(:user)
    ~> preload(req)
    |> to_response()
  end

  def change_password(%Request{identifiers: %{"reset_token" => reset_token}} = req) do
    user =
      req
      |> Map.put(:identifiers, %{"password_reset_token" => reset_token})
      |> to_query(User)
      |> Repo.one()

    req
    |> to_command(%ChangePassword{
        user_id: (user || %{id: uuid4()}).id,
        reset_token: reset_token
      })
    |> dispatch_and_wait(PasswordChanged)
    ~> Map.get(:user)
    ~> preload(req)
    |> to_response()
  end

  def change_password(_), do: {:error, :not_found}

  @doc """
  Delete a managed user.
  """
  @spec delete_user(Request.t()) :: Context.resp()
  def delete_user(%Request{} = req) do
    identifiers = atomize_keys(req.identifiers, ["id"])

    req
    |> to_command(%DeleteUser{})
    |> Map.put(:user_id, identifiers[:id])
    |> dispatch_and_wait(UserDeleted)
    ~> Map.get(:user)
    |> to_response()
  end

  @doc """
  List all managed user of an account.
  """
  @spec list_user(Request.t()) :: Context.resp()
  def list_user(%Request{} = req) do
    req
    |> expand()
    |> authorize(:list_user)
    ~> to_query(User)
    ~> Repo.all()
    ~> preload(req)
    |> to_response()
  end

  @doc """
  Count the number of managed user of an account.
  """
  def count_user(%Request{} = req) do
    req
    |> expand()
    |> Map.put(:pagination, nil)
    |> authorize(:list_user)
    ~> to_query(User)
    ~> Repo.aggregate(:count, :id)
    |> to_response()
  end

  @doc """
  Get a specific user.
  """
  @spec get_user(Request.t()) :: Context.resp()
  def get_user(%Request{} = req) do
    req
    |> expand()
    |> authorize(:get_user)
    ~> account_id_by_identifiers()
    ~> to_query(User)
    ~> Repo.one()
    ~> check_password(req)
    ~> check_account_id(req)
    ~> preload(req)
    |> to_response()
  end

  defp account_id_by_identifiers(%{identifiers: %{"id" => _}} = req) do
    Request.put(req, :account_id, nil)
  end

  defp account_id_by_identifiers(req), do: req

  defp check_password(nil, _), do: nil

  defp check_password(user, %{identifiers: %{"password" => password}}) do
    if User.is_password_valid?(user, password) do
      user
    else
      nil
    end
  end

  defp check_password(user, _), do: user

  defp check_account_id(nil, _), do: nil
  defp check_account_id(%{account_id: nil} = user, _), do: user

  defp check_account_id(%{account_id: aid} = user, %{account_id: t_aid}) do
    if aid == Account.bare_id(t_aid) do
      user
    else
      nil
    end
  end

  defp check_account_id(_, _), do: nil

  @doc """
  List all the accounts owned by a standard user.
  """
  @spec list_account(Request.t()) :: Context.resp()
  def list_account(%Request{} = req) do
    req
    |> expand()
    |> authorize(:list_account)
    ~> Map.put(:account_id, nil)
    ~> Map.put(:filter, [%{"mode" => "live"}, %{"status" => "active"}])
    ~> to_query(Account)
    ~> Repo.all()
    ~> preload(req)
    |> to_response()
  end

  @doc """
  Count the number of accounts owned by a standard user.
  """
  def count_account(%Request{} = req) do
    req
    |> expand()
    |> Map.put(:pagination, nil)
    |> authorize(:list_account)
    ~> Map.put(:account_id, nil)
    ~> Map.put(:filter, [%{"mode" => "live"}, %{"status" => "active"}])
    ~> to_query(Account)
    ~> Repo.aggregate(:count, :id)
    |> to_response()
  end

  @doc """
  Create an account.
  """
  @spec create_account(Request.t()) :: Context.resp()
  def create_account(%Request{} = req) do
    req
    |> to_command(%CreateAccount{})
    |> Map.put(:account_id, nil)
    |> Map.put(:owner_id, req.requester_id)
    |> Map.put(:mode, "live")
    |> dispatch_and_wait(AccountCreated)
    ~> Map.get(:account)
    ~> preload(req)
    |> to_response()
  end

  @doc """
  Get an account.
  """
  @spec get_account(Request.t()) :: Context.resp()
  def get_account(%Request{identifiers: %{"handle" => _}} = req) do
    req
    |> expand()
    |> Request.put(:identifiers, "status", "active")
    |> authorize(:get_account)
    ~> to_query(Account)
    ~> Repo.one()
    ~> Account.put_prefixed_id()
    |> to_response()
  end

  def get_account(%Request{} = req) do
    req
    |> expand()
    |> authorize(:get_account)
    ~> Map.get(:_account_)
    ~> Account.put_prefixed_id()
    |> to_response()
  end

  @doc """
  Update the general information of an account.
  """
  @spec update_account_info(Request.t()) :: Context.resp()
  def update_account_info(%Request{} = req) do
    req
    |> to_command(%UpdateAccountInfo{})
    |> dispatch_and_wait(AccountInfoUpdated)
    ~> Map.get(:account)
    ~> preload(req)
    |> to_response()
  end

  @doc """
  Close an account.
  """
  @spec close_account(Request.t()) :: Context.resp()
  def close_account(%Request{} = req) do
    identifiers = atomize_keys(req.identifiers, ["id"])

    req
    |> to_command(%CloseAccount{})
    |> Map.put(:account_id, identifiers[:id])
    |> dispatch_and_wait(AccountClosed)
    ~> Map.get(:account)
    |> to_response()
  end

  @doc """
  Get a refresh token.
  """
  @spec get_refresh_token(Request.t()) :: Context.resp()
  def get_refresh_token(%Request{} = req) do
    req = expand(req)

    req
    |> authorize(:get_refresh_token)
    ~> get_refresh_token_normalize()
    ~> to_query(RefreshToken)
    ~> Repo.one()
    ~> RefreshToken.put_prefixed_id(req._account_)
    |> to_response()
  end

  defp get_refresh_token_normalize(%{identifiers: %{"id" => id}} = req) do
    Request.put(req, :identifiers, "id", RefreshToken.bare_id(id))
  end

  defp get_refresh_token_normalize(req), do: req

  @doc """
  Exchange the given refresh token identified by its ID for a refresh token of
  the same user but for the account specified by `account_id` of the request.

  If the given refresh token is already for the specified account, then it is simply
  returned.

  This function is intended for exchanging a live refresh token for a corresponding
  test refresh token or for another live refresh token owned by the same user but
  for a different account.
  """
  @spec exchange_refresh_token(Request.t()) :: Context.resp()
  def exchange_refresh_token(%Request{} = req) do
    req = expand(req)

    req
    |> authorize(:exchange_refresh_token)
    ~> do_exchange_refresh_token()
    ~> RefreshToken.put_prefixed_id(req._account_)
    |> to_response()
  end

  defp do_exchange_refresh_token(%{_account_: nil}), do: nil

  defp do_exchange_refresh_token(%{_account_: account, identifiers: %{"id" => id}}) do
    refresh_token = Repo.get(RefreshToken, RefreshToken.bare_id(id))

    cond do
      is_nil(refresh_token) ->
        nil

      # Exchanging for the same account
      refresh_token.account_id == account.id ->
        refresh_token

      # Exchanging for the test account
      refresh_token.account_id == account.live_account_id ->
        Repo.get_by(RefreshToken, account_id: account.id, user_id: refresh_token.user_id)

      # Exchanging for other live account owned by the same user
      refresh_token.user_id == account.owner_id ->
        Repo.get_by(RefreshToken, account_id: account.id, user_id: refresh_token.user_id)

      true ->
        nil
    end
  end

  @doc """
  Add an app to an account.

  ## Authorization

  Only user with the following roles can add an app: `"owner"`, `"administrator"`, `"developer"`.
  """
  @spec add_app(Request.t()) :: Context.resp()
  def add_app(%Request{} = req) do
    req
    |> to_command(%AddApp{})
    |> dispatch_and_wait(AppAdded)
    ~> Map.get(:app)
    ~> preload(req)
    ~> App.put_prefixed_id()
    |> to_response()
  end

  @doc """
  Get an app.
  """
  @spec get_app(Request.t()) :: Context.resp()
  def get_app(%Request{} = req) do
    req
    |> expand()
    |> authorize(:get_app)
    ~> get_app_normalize()
    ~> to_query(App)
    ~> Repo.one()
    ~> App.put_prefixed_id()
    |> to_response()
  end

  defp get_app_normalize(%{identifiers: %{"id" => id}} = req) do
    Request.put(req, :identifiers, "id", App.bare_id(id))
  end

  defp get_app_normalize(req), do: req

  @doc """
  List all app of an account.
  """
  @spec list_app(Request.t()) :: Context.resp()
  def list_app(%Request{} = req) do
    req = expand(req)

    req
    |> authorize(:list_app)
    ~> to_query(App)
    ~> Repo.all()
    ~> preload(req)
    ~> App.put_account(req._account_)
    ~> App.put_prefixed_id()
    |> to_response()
  end

  @doc """
  Count the number of apps of an account.
  """
  def count_app(%Request{} = req) do
    req
    |> expand()
    |> Map.put(:pagination, nil)
    |> authorize(:list_app)
    ~> to_query(App)
    ~> Repo.aggregate(:count, :id)
    |> to_response()
  end

  @doc """
  Update an app.
  """
  @spec update_app(Request.t()) :: Context.resp()
  def update_app(%Request{} = req) do
    identifiers = atomize_keys(req.identifiers, ["id"])

    req
    |> to_command(%UpdateApp{})
    |> Map.put(:app_id, identifiers[:id])
    |> dispatch_and_wait(AppUpdated)
    ~> Map.get(:app)
    ~> preload(req)
    |> to_response()
  end

  @doc """
  Delete an app from an account.
  """
  @spec delete_app(Request.t()) :: Context.resp()
  def delete_app(%Request{} = req) do
    identifiers = atomize_keys(req.identifiers, ["id"])

    req
    |> to_command(%DeleteApp{})
    |> Map.put(:app_id, identifiers[:id])
    |> dispatch_and_wait(AppDeleted)
    ~> Map.get(:app)
    |> to_response()
  end

  defp dispatch_and_wait(cmd, event) do
    dispatch_and_wait(cmd, event, &wait/1)
  end

  defp wait(%UserRegistered{user_id: user_id, }) do
    Projector.wait([
      {:user, UserProjector, &(&1.id == user_id)},
      {:live_account, AccountProjector, &(&1.owner_id == user_id && &1.mode == "live")},
      {:test_account, AccountProjector, &(&1.owner_id == user_id && &1.mode == "test")},
      {:live_app, AppProjector, &(!!&1)},
      {:test_app, AppProjector, &(!!&1)}
    ])
  end

  defp wait(%et{user_id: user_id}) when et in [UserAdded, UserInfoUpdated, DefaultAccountChanged, UserRoleChanged, PasswordResetTokenGenerated, PasswordChanged, UserDeleted] do
    Projector.wait([
      {:user, UserProjector, &(&1.id == user_id)}
    ])
  end

  defp wait(%et{account_id: account_id}) when et in [AccountCreated, AccountInfoUpdated, AccountClosed] do
    Projector.wait([
      {:account, AccountProjector, &(&1.id == account_id)}
    ])
  end

  defp wait(%et{app_id: app_id}) when et in [AppAdded, AppUpdated, AppDeleted] do
    Projector.wait([
      {:app, AppProjector, &(&1.id == app_id)}
    ])
  end
end