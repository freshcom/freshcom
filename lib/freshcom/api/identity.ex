defmodule Freshcom.Identity do
  @moduledoc """
  This API module provides functions that deal with identity and access management.
  It follows a combination of Stripe and AWS style IAM.

  Generally speaking, identity in Freshcom consist of three resources:
  - The app that is making the request on behalf of the user (the client)
  - The account that the request is targeting
  - The user that is making the request (the requester)

  These three resources are used together to authorize each request. ID of
  these 3 resources are required for all API module functions which means the
  `:client_id`, `:account_id` and `:requester_id` (collectively referred as "identity fields")
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

  In most cases it is not secure to allow a user to directly pass in the
  `:user_id` and `:account_id` because these IDs are not changeable and cannot be deleted
  if compromised, so freshcom provides you with API keys that can help you implement
  your authentication method. Using a API key you can retrieve the `:account_id`
  and `:user_id` it belongs to, it can also be easily re-generated in case it is compromised.

  Standard user have an API Key for each account they own including test accounts.
  Managed user for a live account have two API keys, one for the live account, one
  for the corresponding test account. Managed user for test account only have one
  API Key. Each account also have an API Key that is not associated with any user
  you can use this API key if you only want to identify the account without any user.

  How you use API keys are completely up to you, you can directly expose them to the user,
  or in the case of [freshcom_web](https://github.com/freshcom/freshcom_web)
  it is used as the refresh token for the actual access token which itself is a JWT
  that contains the `:account_id` and `:user_id`.

  ## Bypass Authorization

  Sometime you will need to make calls to an API module's function without having the identity
  information. This is especially the case when you are implementing your own authentication
  method on top of freshcom's Elixir API. For example in [freshcom_web](https://github.com/freshcom/freshcom_web)
  the API key needs to be retrieved before a user is authenticated, but the `get_api_key/1`
  function requires all identity fields be provided.

  To solve this problem, freshcom allow you bypass authorization by setting
  the value of `:_role_` of the request struct. If you set the value of `:_role_`
  to any of the following then authorization will be bypassed:
  `"system"`, `"sysdev"`, `"appdev"`. When authorizatino is bypassed you can omit
  all identity fields, however we recommand you still provide as much as you know
  so they can still be logged and useful for debugging and auditing.

  The authorization bypass works for all API module functions, however we recommand
  you only bypass when necessary.

  ### Example to bypass authorization

   ```
  alias Freshcom.{Identity, Request}

  Identity.get_api_key(%Request{
    identifier: %{"id" => "cae028f2-f5e8-402d-a0b9-4bf5ae478151"},
    _role_: "system"
  })
  ```

  ## Role Groups

  For the purpose of this documentation we group user roles in to the following groups:

  - Customer Management Roles: `"owner"`, `"administrator"`, `"manager"`, `"developer"`,  `"support_specialist"`
  - Development Roles: `"owner"`, `"administrator"`, `"developer"`
  - Admin Roles: `"owner"`, `"administrator"`

  ## Abbreviation

  For better formatting the following abbreviation are used in the documentation:

  - C/S: Case Sensitive
  """
  use Freshcom, :api_module

  import FCSupport.Normalization, only: [atomize_keys: 2]
  import Freshcom.IdentityPolicy
  import UUID

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

  alias Freshcom.{UserProjector, AccountProjector, AppProjector}
  alias Freshcom.{User, Account, APIKey, App}

  @doc """
  Register a standard user.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.register_user(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    data: %{
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

  ## Identity Fields

  | Key          | Description                                                 |
  |--------------|-------------------------------------------------------------|
  | `:client_id` | _(required)_ Must be the ID of an app with type `"system"`. |

  ## Data Fields

  | Key                  | Type      | Description                                                                                                                                                 |
  |----------------------|-----------|--------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"username"`         | _String_  | _(required)_ Must be unique across all standard user. Length between 3 and 120 characters. Can contain alphanumeric characters and `'`, `.`, `+`, `-`, `@`. |
  | `"password"`         | _String_  | _(required)_ Must be at least 8 characters long.                                                                                                            |
  | `"is_term_accepted"` | _Boolean_ | _(required)_ Must be true.                                                                                                                                  |
  | `"email"`            | _String_  | Must be in correct format.                                                                                                                                  |
  | `"name"`             | _String_  | Name of the user.                                                                                                                                           |
  | `"account_name"`     | _String_  | Name of the default account to be created, defaults to `"Unnamed Account"`.                                                                                 |
  | `"default_locale"`   | _String_  | Default locale of the default account, defaults to `"en"`.                                                                                                                      |

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
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    data: %{
      "username" => "testuser",
      "password" => "test1234",
      "role" => "developer",
      "email" => "test@example.com",
      "name" => "Demo User"
    }
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                       |
  |-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user. Must be a system app.  |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                        |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a user with role in [Admin Roles](#module-roles).           |

  ## Data Fields

  | Key            | Type     | Description                                                                                                                                                 |
  |----------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"username"`   | _String_ | _(required)_ Must be unique across all standard user. Length between 3 and 120 characters. Can contain alphanumeric characters and `'`, `.`, `+`, `-`, `@`. |
  | `"password"`   | _String_ | _(required)_ Must be at least 8 characters long.                                                                                                            |
  | `"role"`       | _String_ | _(required)_ Please see `Freshcom.User` for list of valid roles.                                                                                            |
  | `"email"`      | _String_ | Must be in correct format.                                                                                                                                  |
  | `"name"`       | _String_ | Full name of the user.                                                                                                                                           |
  | `"first_name"` | _String_ | First name of the user. |
  | `"last_name"`  | _String_ | Last name of the user. |

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
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    identifier: %{"id" => "8d168caa-dc9c-420e-bd88-7474463bcdea"},
    data: %{
      "name" => "Demo User"
    }
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user. Must be a system app if the target user is a standard user.              |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                                  |
  | `:requester_id` | _(required)_ ID of the user making the request. Must meet one of the following conditions: <ul style="margin: 0px;"><li>be the same user as the target user</li><li>be a user with role in [Customer Management Roles](#module-roles) if the target user is of role `"customer"`</li><li>be a user with role in [Admin Roles](#module-roles) if the target user is a managed user</li></ul> |

  ## Identifier Fields

  | Key       | Description                                                                                               |
  |-----------|-----------------------------------------------------------------------------------------------------------|
  | `"id"`    | _(required)_ ID of the target user.                                                                       |

  ## Data Fields

  | Key                  | Type     | Description                                                                                                                                                 |
  |----------------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"username"`         | _String_ | Must be unique across all standard user. Length between 3 and 120 characters. It can contain alphanumeric characters and `'`, `.`, `+`, `-`, `@`. |
  | `"email"`            | _String_ | Must be in correct format.                                                                                                                                  |
  | `"name"`             | _String_ | Full name of the user. |
  | `"first_name"`       | _String_ | First name of the user. |
  | `"last_name"`        | _String_ | Last name of the user. |
  | `"custom_data"`      | _Map_    | Set of key-value pairs that you can attach to this resource. |

  """
  @spec update_user_info(Request.t()) :: APIModule.resp()
  def update_user_info(%Request{} = req) do
    identifier = atomize_keys(req.identifier, ["id"])
    req = expand(req)

    req
    |> to_command(%UpdateUserInfo{})
    |> Map.put(:user_id, identifier[:id])
    |> dispatch_and_wait(UserInfoUpdated)
    ~> Map.get(:user)
    ~> preload(req)
    ~> translate(req.locale, req._default_locale_)
    |> to_response()
  end

  @doc """
  Change the default account of a standard user.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.change_default_account(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    data: %{"id" => "3a0ab0a2-1865-4f80-9127-e2d413ba4b5e"}
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                      |
  |-----------------|--------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user. Must be a system app. |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a standard user.                                          |

  ## Data Fields

  | Key    | Type     | Description                                                                                          |
  |--------|----------|------------------------------------------------------------------------------------------------------|
  | `"id"` | _String_ | _(required)_ ID of the new default account. The provided account must be owned by the requester. |

  """
  @spec change_default_account(Request.t()) :: APIModule.resp()
  def change_default_account(%Request{} = req) do
    req
    |> to_command(%ChangeDefaultAccount{})
    |> Map.put(:user_id, req.requester_id)
    |> Map.put(:account_id, req.data["id"])
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
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    identifier: %{"id" => "8d168caa-dc9c-420e-bd88-7474463bcdea"},
    data: %{"value" => "manager"}
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user.                                                                       |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                                  |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a user with role in [Admin Roles](#module-roles). |

  ## Identifier Fields

  | Key    | Type     | Description                                                                                                                                                 |
  |--------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"id"` | _String_ | _(required)_ ID of the target user. Must be a managed user and cannot be the same as the requester. |

  ## Data Fields

  | Key       | Type     | Description                                                                                                                                                 |
  |-----------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"value"` | _String_ | _(required)_ New role of the user. |

  """
  @spec change_user_role(Request.t()) :: APIModule.resp()
  def change_user_role(%Request{} = req) do
    cmd = %ChangeUserRole{
      user_id: req.identifier["id"],
      role: req.data["value"]
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

  - By providing the username of the user, using a username you can generate a reset token for both standard and managed user.
  - By providing the ID of the user, using the user ID you can only generate a reset token for managed user.

  ## Examples

  ### Using user's username
  ```
  alias Freshcom.{Identity, Request}

  Identity.generate_password_reset_token(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    identifier: %{"username" => "roy"}
  })
  ```

  ### Using user's ID
  ```
  alias Freshcom.{Identity, Request}

  Identity.generate_password_reset_token(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    identifier: %{"id" => "8d168caa-dc9c-420e-bd88-7474463bcdea"}
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user. Must be a system app if the target user is a standard user.                     |
  | `:account_id`   | ID of the target account, if provided will only look for managed user of the target account, otherwise will only look for standard user.                     |
  | `:requester_id` | ID of the user making the request, required if `identifier["id"]` is provided. Must meet one of the following conditions: <ul style="margin: 0px;"><li>be a user with role in [Customer Management Roles](#module-roles) if the target user is of role `"customer"`</li><li>be a user with role in [Admin Roles](#module-roles)</li></ul> |

  ## Identifier Fields

  | Key          | Type     | Description                                                                                                                                                 |
  |--------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"id"`       | _String_ | ID of the target user, required if `identifier["username"]` is not provided. Must be the ID a managed user.  |
  | `"username"` | _String_ | Username of the target user, required if `identifier["id"]` is not provided. |

  """
  @spec generate_password_reset_token(Request.t()) :: APIModule.resp()
  def generate_password_reset_token(%Request{identifier: %{"username" => username}} = req) do
    user =
      req
      |> Map.put(:identifier, %{"username" => username})
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

  def generate_password_reset_token(%Request{identifier: %{"id" => id}} = req) do
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
    identifier: %{"reset_token" => reset_token},
    data: %{"new_password" => "test1234"}
  })
  ```

  ### Using the user's ID
  ```
  alias Freshcom.{Identity, Request}

  Identity.change_password(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    identifier: %{"id" => "8d168caa-dc9c-420e-bd88-7474463bcdea"},
    data: %{"new_password" => "test1234"}
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user. Must be a system app if the target user is a standard user. |
  | `:account_id`   | ID of the target account, required if `identifier["reset_token"]` is not provided.                                                                          |
  | `:requester_id` | ID of the user making the request, required if `identifier["reset_token"]` is not provided. When required must be the same as `identifier["id"]` or be a user with role `"owner"` or `"administrator"`. |

  ## Identifier Fields

  | Key                  | Type     | Description                                                                                                                                                 |
  |----------------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"id"`               | _String_ | ID of the target user, required if `identifier["reset_token"]` is not provided. |
  | `"reset_token"`      | _String_ | A password reset token of the target user, required if `identifier["id"]` is not provided.|

  ## Data Fields

  | Key                  | Type     | Description                                                                                                                                                 |
  |----------------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"new_password"`     | _String_ | _(required)_ New password of the user. Must be at least 8 character long.                                                                                   |
  | `"current_password"` | _String_ | Current password of the user, required if requester is the same as target user.  |

  """
  @spec change_password(Request.t()) :: APIModule.resp()
  def change_password(%Request{identifier: %{"reset_token" => reset_token}} = req) do
    user =
      req
      |> Map.put(:identifier, %{"password_reset_token" => reset_token})
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

  def change_password(%Request{identifier: %{"id" => id}} = req) do
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
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    identifier: %{"id" => "8d168caa-dc9c-420e-bd88-7474463bcdea"}
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user.                                                                       |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                                  |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a user with role in [Admin Roles](#module-roles). |

  ## Identifier Fields

  | Key     | Type     | Description                                                                                                                                                 |
  |---------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"id"`  | _String_ | _(required)_ ID of the target user. Must be a managed user and cannot be the same as the requester. |

  """
  @spec delete_user(Request.t()) :: APIModule.resp()
  def delete_user(%Request{} = req) do
    identifier = atomize_keys(req.identifier, ["id"])

    req
    |> to_command(%DeleteUser{})
    |> Map.put(:user_id, identifier[:id])
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
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    filter: [%{"role" => "customer"}],
    search: "roy"
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                               |
  |-----------------|-----------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user.                              |
  | `:account_id`   | _(required)_ ID of the target account.                                                                    |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a user with role in [Admin Roles](#module-roles). |

  ## Filter Fields

  | Key                     | Type                | [C/S](#module-abbreviation) | Supported Operators | Default                                 |
  |-------------------------|---------------------|------|---------------------------------------|----------------------------------------------|
  | `"status"`              | _String_            | Yes  | [Equality Operators](Freshcom.Filter.html#module-operator-groups) | `%{"$eq" => "active"}` |
  | `"username"`            | _String_            | No   | [Equality Operators](Freshcom.Filter.html#module-operator-groups) | N/A |
  | `"email"`               | _String_            | No   | [Equality Operators](Freshcom.Filter.html#module-operator-groups) | N/A |
  | `"name"`                | _String_            | Yes  | [Equality Operators](Freshcom.Filter.html#module-operator-groups) | N/A |
  | `"first_name"`          | _String_            | Yes  | [Equality Operators](Freshcom.Filter.html#module-operator-groups) | N/A |
  | `"last_name"`           | _String_            | Yes  | [Equality Operators](Freshcom.Filter.html#module-operator-groups) | N/A |
  | `"role"`                | _String_            | Yes  | [Equality Operators](Freshcom.Filter.html#module-operator-groups) | N/A |
  | `"email_verified"`      | _Boolean_           | N/A  | `"$eq"` | N/A |
  | `"email_verified_at"`   | _String_ (ISO8601)  | N/A  | `"$eq"` and [Range Operators](Freshcom.Filter.html#module-operator-groups) | N/A |
  | `"password_changed_at"` | _String_ (ISO8601)  | N/A  | `"$eq"` and [Range Operators](Freshcom.Filter.html#module-operator-groups) | N/A |

  Please see `Freshcom.Filter` for details on how to use filter.

  ## Other Fields

  - Searchable fields: `["name", "username", "email"]`
  - Sortable fields: `["status", "username", "email", "role"]`

  """
  @spec list_user(Request.t()) :: APIModule.resp()
  def list_user(%Request{} = req) do
    req = expand(req)

    req
    |> Map.put(:_filterable_keys_, [
      "status",
      "username",
      "email",
      "name",
      "first_name",
      "last_name",
      "role",
      "email_verified",
      "email_verified_at",
      "password_changed_at"
    ])
    |> Map.put(:_searchable_keys_, ["name", "username", "email"])
    |> Map.put(:_sortable_keys_, ["status", "username", "email", "role"])
    |> authorize(:list_user)
    ~> to_query(User)
    ~> Repo.all()
    ~> preload(req)
    ~> translate(req.locale, req._default_locale_)
    |> to_response()
  end

  @doc """
  Count the number of managed user of an account.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.count_user(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    filter: [%{"role" => "customer"}],
    search: "roy"
  })
  ```

  ## Request Fields

  All fields are the same as `list_user/1`, except any pagination will be ignored.

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
  Get the details of a specific user.

  There are two ways to get a user:

  - By providing the username and password of a user
  - By providing a user ID

  ## Examples

  ### Using username and password
  ```
  alias Freshcom.{Identity, Request}

  Identity.get_user(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    identifier: %{
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
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    identifier: %{"id" => "8d168caa-dc9c-420e-bd88-7474463bcdea"}
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                       |
  |-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user. |
  | `:account_id`   | ID of the target account, required if the target user is a managed user.                                                                                                        |
  | `:requester_id` | ID of the user making the request, required if `identifier["id"]` is provided. When required, must be the same as the target user or be a user with role in [Admin Roles](#module-roles).           |

  ## Identifier Fields

  | Key          | Type     | Description                                                                                                                                                 |
  |--------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"id"`       | _String_ | ID of the target user, required if `identifier["username"]` and `identifier["password"]` is not provided. |
  | `"username"` | _String_ | Username of the target user, required if `identifier["id"]` is not provided. |
  | `"password"` | _String_ | Password of the target user, required if `identifier["id"]` is not provided. |
  | `"type"`     | _String_ | Type of the target user. |

  """
  @spec get_user(Request.t()) :: APIModule.resp()
  def get_user(%Request{} = req) do
    req = expand(req)

    req
    |> authorize(:get_user)
    ~> account_id_by_identifier()
    ~> to_query(User)
    ~> Repo.one()
    ~> check_password(req)
    ~> check_account_id(req)
    ~> preload(req)
    ~> translate(req.locale, req._default_locale_)
    |> to_response()
  end

  defp account_id_by_identifier(%{identifier: %{"id" => _}} = req) do
    Request.put(req, :account_id, nil)
  end

  defp account_id_by_identifier(req), do: req

  defp check_password(nil, _), do: nil

  defp check_password(user, %{identifier: %{"password" => password}}) do
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

  Only live account with `"active"` status can be listed.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.list_account(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4"
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                       |
  |-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user. Must be a system app.  |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a standard user.           |

  """
  @spec list_account(Request.t()) :: APIModule.resp()
  def list_account(%Request{} = req) do
    req
    |> expand()
    |> Map.put(:_searchable_keys_, [])
    |> Map.put(:_sortable_keys_, [])
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
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    requester_id: "c59ca218-3850-497b-a03f-a0584e5c7763"
  })
  ```

  ## Request Fields

  All fields are the same as `list_account/1`, except any pagination will be ignored.

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
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    data: %{
      "name" => "SpaceX",
      "default_locale" => "en"
    }
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                       |
  |-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user. Must be a system app.  |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a standard user.           |

  ## Data Fields

  | Key                  | Type      | Description                                                                                                                                                 |
  |----------------------|-----------|--------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"name"`             | _String_  | Name of the default account to be created, defaults to `"Unnamed Account"`.                                                                                 |
  | `"default_locale"`   | _String_  | Default locale of the default account, defaults to `"en"`.                                                                                                                      |

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
  Get the details of an account.

  There are two ways to get an account:

  - Using an account handle
  - Using an account ID

  ## Examples

  ### Using an account handle

  ```
  alias Freshcom.{Identity, Request}

  Identity.get_account(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    identifier: %{"handle" => "freshcom"}
  })
  ```

  ### Using an account ID

  ```
  alias Freshcom.{Identity, Request}

  Identity.get_account(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763"
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                       |
  |-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user.  |
  | `:account_id`   | ID of the target account, required if `identifier["handle"]` is not provided.                                                                    |
  | `:requester_id` | ID of the user making the request.           |

  ## Identifier Fields

  | Key          | Type     | Description                                                                                                                                                 |
  |--------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"handle"`   | _String_ | ID of the target account, required if `:account_id` is not provided. |

  """
  @spec get_account(Request.t()) :: APIModule.resp()
  def get_account(%Request{identifier: %{"handle" => _}} = req) do
    req
    |> expand()
    |> Map.put(:_identifiable_keys_, ["handle"])
    |> authorize(:get_account)
    ~> to_query(Account)
    ~> Repo.one()
    ~> Account.put_prefixed_id()
    |> to_response()
  end

  def get_account(%Request{} = req) do
    req
    |> expand()
    |> Map.put(:_identifiable_keys_, ["id"])
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
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    data: %{
      "handle" => "spacex",
      "name" => "SpaceX",
      "caption" => "A new age of space exploration starts...",
      "description" => "What more do you want?"
    }
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                       |
  |-----------------|---------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user.  |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                        |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a user with role in [Admin Roles](#module-roles).           |

  ## Data Fields

  | Key                  | Type     | Description                                                                                                                                                 |
  |----------------------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"handle"`           | _String_ | A unique identifier of the account, must be unique across all accounts. |
  | `"name"`             | _String_ | Name of the account.                                                                                                                                  |
  | `"caption"`          | _String_ | Short description of the account. |
  | `"description"`      | _String_ | Long description of the account. |
  | `"custom_data"`      | _Map_    | Set of key-value pairs that you can attach to this resource. |

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
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4"
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user. Must be a system app.                                                                       |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                                  |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a standard user that owns the target account. |

  """
  @spec close_account(Request.t()) :: APIModule.resp()
  def close_account(%Request{} = req) do
    identifier = atomize_keys(req.identifier, ["id"])

    req
    |> to_command(%CloseAccount{})
    |> Map.put(:account_id, identifier[:id])
    |> dispatch_and_wait(AccountClosed)
    ~> Map.get(:account)
    |> to_response()
  end

  @doc """
  Get the details an API Key.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.get_api_key(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4"
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user.                                                                       |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                                  |
  | `:requester_id` | _(required)_ ID of the user making the request. Must meet one of the following conditions: <ul style="margin: 0px;"><li>be the same as `identifier["user_id"]` if that is provided</li><li>be a user with role in [Admin Roles](#module-roles).</li></ul> |

  ## Identifier Fields

  | Key            | Description                                                                                               |
  |----------------|-----------------------------------------------------------------------------------------------------------|
  | `"user_id"`    | ID of the target user, if provided will get user specific API keys, otherwise will only get the account's publishable API key.  |

  """
  @spec get_api_key(Request.t()) :: APIModule.resp()
  def get_api_key(%Request{} = req) do
    req = expand(req)

    req
    |> Map.put(:_identifiable_keys_, ["id", "user_id"])
    |> authorize(:get_api_key)
    ~> get_api_key_normalize()
    ~> to_query(APIKey)
    ~> Repo.one()
    ~> APIKey.put_prefixed_id(req._account_)
    |> to_response()
  end

  defp get_api_key_normalize(%{identifier: %{"id" => id}} = req) do
    Request.put(req, :identifier, "id", APIKey.bare_id(id))
  end

  defp get_api_key_normalize(%{identifier: identifier} = req) do
    if !identifier["user_id"] do
      Map.put(req, :identifier, %{"user_id" => nil})
    else
      req
    end
  end

  defp get_api_key_normalize(req), do: req

  @doc """
  Exchange the given API key an API Key of the same user but for a differnt account.

  If the given API Key is already for the specified account, then it is simply
  returned.

  This function is intended for exchanging a live API Key for a corresponding
  test API Key or for another live API Key owned by the same user but
  for a different account.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.exchange_api_key(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    data: %{"id" => "cae028f2-f5e8-402d-a0b9-4bf5ae478151"}
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user.                                                                       |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                                  |
  | `:requester_id` | ID of the user making the request. |

  ## Data Fields

  | Key       | Description                                                                                               |
  |-----------|-----------------------------------------------------------------------------------------------------------|
  | `"id"`    | _(required)_ ID of the API key. |

  """
  @spec exchange_api_key(Request.t()) :: APIModule.resp()
  def exchange_api_key(%Request{} = req) do
    req = expand(req)

    req
    |> authorize(:exchange_api_key)
    ~> do_exchange_api_key()
    ~> APIKey.put_prefixed_id(req._account_)
    |> to_response()
  end

  defp do_exchange_api_key(%{_account_: nil}), do: nil

  defp do_exchange_api_key(%{_account_: account, identifier: %{"id" => id}}) do
    api_key = Repo.get(APIKey, APIKey.bare_id(id))

    cond do
      is_nil(api_key) ->
        nil

      # Exchanging for the same account
      api_key.account_id == account.id ->
        api_key

      # Exchanging for the test account
      api_key.account_id == account.live_account_id ->
        Repo.get_by(APIKey, account_id: account.id, user_id: api_key.user_id)

      # Exchanging for other live account owned by the same user
      api_key.user_id == account.owner_id ->
        Repo.get_by(APIKey, account_id: account.id, user_id: api_key.user_id)

      true ->
        nil
    end
  end

  @doc """
  Add an app to an account.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.add_app(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    data: %{
      "name" => "Test"
    }
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                                   |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user. Must be a system app.                              |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                                                    |
  | `:requester_id` | _(required)_ ID of the user making the request.<br/> Must be a user with role `"owner"`, `"administrator"` or `"developer"`. |

  ## Data Fields

  | Key      | Type     | Description                   |
  |----------|----------|-------------------------------|
  | `"name"` | _String_ | _(required)_ Name of the app. |

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
  Get the details of an app.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.get_app(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    identifier: %{"id" => "8d168caa-dc9c-420e-bd88-7474463bcdea"}
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user.                                                                       |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                                  |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a user with role in [Development Roles](#module-roles). |

  ## Identifier Fields

  | Key       | Description                                                                                               |
  |-----------|-----------------------------------------------------------------------------------------------------------|
  | `"id"`    | _(required)_ ID of the target app.                                                                       |

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

  defp get_app_normalize(%{identifier: %{"id" => id}} = req) do
    Request.put(req, :identifier, "id", App.bare_id(id))
  end

  defp get_app_normalize(req), do: req

  @doc """
  List all app of an account.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.list_app(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4"
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user.                                                                       |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                                  |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a user with role in [Development Roles](#module-roles). |

  """
  @spec list_app(Request.t()) :: APIModule.resp()
  def list_app(%Request{} = req) do
    req = expand(req)

    req
    |> Map.put(:_filterable_keys_, [])
    |> Map.put(:_searchable_keys_, [])
    |> Map.put(:_sortable_keys_, [])
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

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.list_app(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4"
  })
  ```

  ## Request Fields

  All fields are the same as `list_app/1`, except any pagination will be ignored.

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

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.update_app(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    identifier: %{"id" => "8d168caa-dc9c-420e-bd88-7474463bcdea"},
    data: %{
      "name" => "Example App"
    }
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user.                                                                       |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                                  |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a user with role in [Development Roles](#module-roles). |

  ## Identifier Fields

  | Key       | Description                                                                                               |
  |-----------|-----------------------------------------------------------------------------------------------------------|
  | `"id"`    | _(required)_ ID of the target app.                                                                       |

  ## Data Fields

  | Key      | Type     | Description                   |
  |----------|----------|-------------------------------|
  | `"name"` | _String_ | Name of the app. |

  """
  @spec update_app(Request.t()) :: APIModule.resp()
  def update_app(%Request{} = req) do
    identifier = atomize_keys(req.identifier, ["id"])

    req
    |> to_command(%UpdateApp{})
    |> Map.put(:app_id, identifier[:id])
    |> dispatch_and_wait(AppUpdated)
    ~> Map.get(:app)
    ~> preload(req)
    |> to_response()
  end

  @doc """
  Delete an app from an account.

  ## Examples

  ```
  alias Freshcom.{Identity, Request}

  Identity.delete_app(%Request{
    client_id: "ab9f27c5-8636-498e-96ab-515de6aba53e",
    account_id: "c59ca218-3850-497b-a03f-a0584e5c7763",
    requester_id: "4df750ca-ea88-4150-8a0b-7bb77efa43a4",
    identifier: %{"id" => "8d168caa-dc9c-420e-bd88-7474463bcdea"}
  })
  ```

  ## Identity Fields

  | Key             | Description                                                                                                                                                 |
  |-----------------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `:client_id`    | _(required)_ ID of the app that is making the request on behalf of the user.                                                                       |
  | `:account_id`   | _(required)_ ID of the target account.                                                                                                                  |
  | `:requester_id` | _(required)_ ID of the user making the request. Must be a user with role in [Development Roles](#module-roles). |

  ## Identifier Fields

  | Key     | Type     | Description                                                                                                                                                 |
  |---------|----------|-------------------------------------------------------------------------------------------------------------------------------------------------------------|
  | `"id"`  | _String_ | _(required)_ ID of the target app. |

  """
  @spec delete_app(Request.t()) :: APIModule.resp()
  def delete_app(%Request{} = req) do
    identifier = atomize_keys(req.identifier, ["id"])

    req
    |> to_command(%DeleteApp{})
    |> Map.put(:app_id, identifier[:id])
    |> dispatch_and_wait(AppDeleted)
    ~> Map.get(:app)
    |> to_response()
  end

  defp dispatch_and_wait(cmd, event) do
    dispatch_and_wait(cmd, event, &wait/1)
  end

  defp wait(%UserRegistered{user_id: user_id}) do
    Projector.wait([
      {:user, UserProjector, &(&1.id == user_id)},
      {:live_account, AccountProjector, &(&1.owner_id == user_id && &1.mode == "live")},
      {:test_account, AccountProjector, &(&1.owner_id == user_id && &1.mode == "test")},
      {:live_app, AppProjector, &(!!&1)},
      {:test_app, AppProjector, &(!!&1)}
    ])
  end

  defp wait(%et{user_id: user_id})
       when et in [
              UserAdded,
              UserInfoUpdated,
              DefaultAccountChanged,
              UserRoleChanged,
              PasswordResetTokenGenerated,
              PasswordChanged,
              UserDeleted
            ] do
    Projector.wait([
      {:user, UserProjector, &(&1.id == user_id)}
    ])
  end

  defp wait(%et{account_id: account_id})
       when et in [AccountCreated, AccountInfoUpdated, AccountClosed] do
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
