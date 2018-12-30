defmodule Freshcom.Identity do
  @moduledoc """
  This API module provides functions that deal with identity and access management.
  It follows a combination of Stripe and AWS style IAM.

  Generally speaking, identity in Freshcom consist of three resources:
  - The user that is making the request (the requester)
  - The app that is making the request on behalf of the user (the client)
  - The account that the request is targeting

  These three resources are used together to authorize each request. The ID of
  these 3 resources are required for all API module functions which means the
  `:requester_id`, `:client_id`, and `:account_id` (collectively referred as "identity fields")
  must be set on the `Freshom.Request` struct unless otherwise indicated in the documentation.

  This module provides functions to help you create and manage these three resources
  and their related resources.

  Note that no module in freshcom actually provides any authentication related
  functions. It is assumed all calls to these functions are already authenticated
  and whatever provided in the identity fields of `Freshcom.Request` struct
  is already validated. It is up to your delivery layer to implement your own authentication
  and make sure the user is who they say they are. For example [freshcom_web](https://github.com/freshcom/freshcom_web)
  uses OAuth with JWT to do authentication.

  ## Resource Relationship

  The relationships between the identity resources are as illustrated in the diagram below.

  <img alt="Relationship Diagram" src="images/identity/relationship.png" width="271px">

  Relationship can be described as follows:

  - Standard user can have multiple account
  - Account can have multiple managed user
  - Account can have multiple app
  - All resources except standard user must belongs to an account

  You can create a standard user by using `Freshcom.Identity.register_user/1`.

  ## Test Account

  There are two types of account in freshcom: live account and test account. Each
  live account will have one test account associated it. User that have access to
  the live account will have the same access level to the corresponding test account
  but not vice versa.

  ## API Key

  In most cases it is not secure to directly allow a user to directly pass in the
  `:user_id` and `:account_id` because these IDs are not changeable and cannot be deleted
  if compromised, so freshcom provides you with API keys that can help you implement
  your authentication method. Using a API key you can retrieve the `:account_id`
  and `:user_id` it belongs to, it can also be easily re-generated in case it is compromised.

  Standard user have an API Key for each account they own including test accounts.
  managed user for a live account have two API keys, one for the live account, one
  for the corresponding test account. Managed user for test account only have one
  API Key. Each account also have an API Key that is not associated with any user
  you can use this API key if you only want to identify the account without any user.

  How you use API keys are completely up to you, you can directly expose them to the user,
  or in the case of [freshcom_web](https://github.com/freshcom/freshcom_web)
  it is used as the refresh token for the actual access token which itself is a JWT
  that contains the `:account_id` and `:user_id`.
  """

  import FCSupport.Normalization, only: [atomize_keys: 2]
  import Freshcom.APIModule
  import Freshcom.IdentityPolicy
  import UUID

  use OK.Pipe

  alias Freshcom.{APIModule, Request}
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
    client_id: client_id,
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

  ## Authorization

  User can only register through an app with type `"system"`.
  """
  @spec register_user(Request.t()) :: APIModule.resp()
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
    requester_id: requester_id,
    client_id: client_id,
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
  @spec add_user(Request.t()) :: APIModule.resp()
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

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.update_user_info(%Request{
    requester_id: requester_id,
    client_id: client_id,
    account_id: account_id,
    identifiers: %{"id" => user_id},
    fields: %{
      "name" => "Demo User"
    }
  })
  ```

  ## Authorization

  - All user can update their own information
  - User with role `"owner"` and `"administrator"` can update the information of other managed user of the same account
  - User with role `"support_specialist"` can update other managed user with role `"customer"`
  """
  @spec update_user_info(Request.t()) :: APIModule.resp()
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

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.change_default_account(%Request{
    requester_id: requester_id,
    client_id: client_id,
    fields: %{"id" => account_id}
  })
  ```

  ## Authorization

  - User can only change their default account through an app with type `"system"`
  - Only standard user can change their default account
  - The target account must be owned by the user
  """
  @spec change_default_account(Request.t()) :: APIModule.resp()
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

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.change_user_role(%Request{
    requester_id: requester_id,
    client_id: client_id,
    account_id: account_id,
    identifiers: %{"id" => user_id},
    fields: %{"value" => "manager"}
  })
  ```

  ## Authorization

  - User cannot change the role of themself
  - User can only change role through an app with type `"system"`
  - User with role `"owner"` and `"administrator"` can change the role of other managed user of the same account
  """
  @spec change_user_role(Request.t()) :: APIModule.resp()
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

  There are two ways to generate a password reset token:

  - By providing the username of the user. If an `account_id` is also provided in
    the request then it will only look for managed user under that account, otherwise
    it will only look for standard user. In this case `requester_id` can be omitted.
  - By providing the ID of the user. In this case the `requester_id` must be provided as well.

  ## Examples

  ### Using user's username
  ```
  alias Freshcom.{Identity, Request}

  Identity.change_user_role(%Request{
    client_id: client_id,
    account_id: account_id,
    identifiers: %{"username" => username}
  })
  ```

  ### Using user's ID
  ```
  alias Freshcom.{Identity, Request}

  Identity.change_user_role(%Request{
    requester_id: requester_id,
    client_id: client_id,
    account_id: account_id,
    identifiers: %{"id" => user_id}
  })
  ```

  ## Authorization

  Standard user can only generate a password reset token through an app with type `"system"`
  """
  @spec generate_password_reset_token(Request.t()) :: APIModule.resp()
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

  There are two ways to change a password:

  - By providing a password reset token.
  - By providing the ID of the user.

  ## Examples

  ### Using a password reset token
  ```
  alias Freshcom.{Identity, Request}

  Identity.change_password(%Request{
    client_id: client.id,
    identifiers: %{"reset_token" => reset_token},
    fields: %{"new_password" => "test1234"}
  })
  ```

  ### Using the user's ID
  ```
  alias Freshcom.{Identity, Request}

  Identity.change_password(%Request{
    requester_id: requester_id,
    client_id: client_id,
    account_id: account_id,
    identifiers: %{"id" => user_id},
    fields: %{"new_password" => "test1234"}
  })
  ```

  ## Authorization

  - If reset token is given, no further authorization is required
  - User can change their own password
  - User with role `"administrator"` and `"owner"` can be change the password of other managed user of the same account
  """
  @spec change_password(Request.t()) :: APIModule.resp()
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

  def change_password(%Request{identifiers: %{"id" => id}} = req) do
    req
    |> to_command(%ChangePassword{})
    |> Map.put(:user_id, id)
    |> dispatch_and_wait(PasswordChanged)
    ~> Map.get(:user)
    ~> preload(req)
    |> to_response()
  end

  def change_password(_), do: {:error, :not_found}

  @doc """
  Delete a managed user.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.delete_user(%Request{
    requester_id: requester_id,
    client_id: client_id,
    account_id: account_id,
    identifiers: %{"id" => user_id}
  })
  ```

  ## Authorization

  - User cannot delete themself
  - User with role `"administrator"` and `"owner"` can delete other managed user of the same account
  """
  @spec delete_user(Request.t()) :: APIModule.resp()
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

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.list_user(%Request{
    requester_id: requester_id,
    client_id: client_id,
    account_id: account_id
  })
  ```

  ## Authorization

  Only user with role `"administrator"` and `"owner"` can list user
  """
  @spec list_user(Request.t()) :: APIModule.resp()
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

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.count_user(%Request{
    requester_id: requester_id,
    client_id: client_id,
    account_id: account_id
  })
  ```

  ## Authorization

  Only user with role `"administrator"` and `"owner"` can count user
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

  There are two ways to get a user:

  - By providing the username and password of a user
  - By providing a user ID

  ## Examples

  ### Using username and password
  ```
  alias Freshcom.{Identity, Request}

  Identity.get_user(%Request{
    identifiers: %{
      "type" => "standard",
      "username" => "demouser",
      "password" => "test1234"
    }
  })
  ```

  ### Using a user ID
  ```
  alias Freshcom.{Identity, Request}

  Identity.get_user(%Request{
    requester_id: requester_id,
    client_id: client_id,
    account_id: account_id,
    identifiers: %{"id" => user_id}
  })
  ```

  ## Authorization

  - User can get themself
  - User with role `"administrator"` and `"owner"` can get other managed user of the same account
  """
  @spec get_user(Request.t()) :: APIModule.resp()
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

  Only live account with `"active"` status is listed.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.list_account(%Request{
    requester_id: requester_id,
    client_id: client_id
  })
  ```

  ## Authorization

  Only standard user can list account through an app with type `"system"`
  """
  @spec list_account(Request.t()) :: APIModule.resp()
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

  Only live account with `"active"` status is counted.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.count_account(%Request{
    requester_id: requester_id,
    client_id: client_id
  })
  ```

  ## Authorization

  Only standard user can count account through an app with type `"system"`
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

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.create_account(%Request{
    requester_id: requester_id,
    client_id: client_id,
    fields: %{
      "name" => "SpaceX",
      "default_locale" => "en"
    }
  })
  ```

  ## Authorization

  Only standard user can create an account through an app with type `"system"`
  """
  @spec create_account(Request.t()) :: APIModule.resp()
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

  There are two ways to get an account:

  - Using an account handle
  - Using an account ID
  """
  @spec get_account(Request.t()) :: APIModule.resp()
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

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.update_account_info(%Request{
    requester_id: requester_id,
    client_id: client_id,
    account_id: account_id,
    fields: %{
      "handle" => "spacex",
      "name" => "SpaceX",
      "caption" => "A new age of space exploration starts...",
      "description" => "What more do you want?"
    }
  })
  ```

  ## Authorization

  Only user with role `"administrator"` and `"owner"` can update the account's general information.
  """
  @spec update_account_info(Request.t()) :: APIModule.resp()
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

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.close_account(%Request{
    requester_id: requester.id,
    client_id: client.id,
    account_id: account_id
  })
  ```

  ## Authorization

  Only user with role `"owner"` can close an account through an app with type `"system"`.
  """
  @spec close_account(Request.t()) :: APIModule.resp()
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
  @spec get_refresh_token(Request.t()) :: APIModule.resp()
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
  @spec exchange_refresh_token(Request.t()) :: APIModule.resp()
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
  @spec add_app(Request.t()) :: APIModule.resp()
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
  @spec get_app(Request.t()) :: APIModule.resp()
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
  @spec list_app(Request.t()) :: APIModule.resp()
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
  @spec update_app(Request.t()) :: APIModule.resp()
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
  @spec delete_app(Request.t()) :: APIModule.resp()
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