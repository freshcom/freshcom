defmodule FCIdentity.RouterTest do
  use FCIdentity.RouterCase, async: true

  import Comeonin.Argon2

  alias FCStateStorage.GlobalStore.{UserRoleStore, UserTypeStore, AppStore}
  alias FCIdentity.Router
  alias FCIdentity.{
    RegisterUser,
    DeleteUser,
    GeneratePasswordResetToken,
    ChangePassword,
    UpdateAccountInfo,
    UpdateUserInfo,
    GenerateEmailVerificationToken,
    VerifyEmail,
    CloseAccount,
    AddApp,
    UpdateApp,
    DeleteApp
  }
  alias FCIdentity.{
    AccountCreated,
    AccountInfoUpdated,
    AccountClosed
  }
  alias FCIdentity.{
    UserRegistered,
    UserAdded,
    UserDeleted,
    ChangeUserRole,
    PasswordResetTokenGenerated,
    PasswordChanged,
    UserRoleChanged,
    UserInfoUpdated,
    EmailVerificationTokenGenerated,
    EmailVerified
  }
  alias FCIdentity.{AppAdded, AppUpdated, AppDeleted}

  def user_id(account_id, role) do
    requester_id = uuid4()
    UserRoleStore.put(requester_id, account_id, role)

    if role == "owner" do
      UserTypeStore.put(requester_id, "standard")
    else
      UserTypeStore.put(requester_id, "managed")
    end

    requester_id
  end

  def app_id(type, account_id \\ nil) do
    app_id = uuid4()
    AppStore.put(app_id, type, account_id)

    app_id
  end

  def account_stream(events) do
    groups = Enum.group_by(events, &(&1.account_id))

    Enum.each(groups, fn({account_id, events}) ->
      append_to_stream("account-" <> account_id, events)
    end)
  end

  def user_stream(events) do
    groups = Enum.group_by(events, &(&1.user_id))

    Enum.each(groups, fn({user_id, events}) ->
      append_to_stream("user-" <> user_id, events)
    end)
  end

  def app_stream(events) do
    groups = Enum.group_by(events, &(&1.app_id))

    Enum.each(groups, fn({app_id, events}) ->
      append_to_stream("app-" <> app_id, events)
    end)
  end

  describe "dispatch RegisterUser" do
    test "with valid command" do
      client_id = app_id("system")

      cmd = %RegisterUser{
        client_id: client_id,
        username: Faker.String.base64(8),
        password: Faker.String.base64(12),
        email: Faker.Internet.email(),
        is_term_accepted: true,
        name: Faker.Name.name()
      }
      :ok = Router.dispatch(cmd)

      assert_receive_event(UserRegistered, fn(event) ->
        assert event.username == cmd.username
        assert event.default_account_id
        assert event.is_term_accepted == cmd.is_term_accepted
        assert event.name == cmd.name
        assert event.email == cmd.email
      end)

      assert_receive_event(EmailVerificationTokenGenerated, fn(event) ->
        assert event.token
        assert event.expires_at
      end)
      assert_receive_event(AccountCreated,
        fn(event) -> event.mode == "live" end,
        fn(event) ->
          assert event.name == "Unamed Account"
          assert event.default_locale == "en"
        end
      )

      assert_receive_event(AccountCreated,
        fn(event) -> event.mode == "test" end,
        fn(event) ->
          assert event.name == "Unamed Account"
          assert event.default_locale == "en"
        end
      )
    end
  end

  describe "dispatch DeleteUser" do
    test "with non existing user id" do
      cmd = %DeleteUser{
        account_id: uuid4(),
        user_id: uuid4()
      }

      {:error, {:not_found, :user}} = Router.dispatch(cmd)
    end

    test "with valid command" do
      account_id = uuid4()
      requester_id = user_id(account_id, "administrator")
      client_id = app_id("standard", account_id)

      user_id = uuid4()
      user_stream([%UserAdded{
        account_id: account_id,
        user_id: user_id,
        type: "managed",
        role: "developer"
      }])

      cmd = %DeleteUser{
        requester_id: requester_id,
        account_id: account_id,
        client_id: client_id,
        user_id: user_id
      }
      :ok = Router.dispatch(cmd)

      assert_receive_event(UserDeleted, fn(event) ->
        assert event.user_id == cmd.user_id
      end)
    end
  end

  describe "dispatch GeneratePasswordResetToken" do
    test "with invalid command" do
      cmd = %GeneratePasswordResetToken{}

      {:error, {:validation_failed, _}} = Router.dispatch(cmd)
    end

    test "with non existing user id" do
      cmd = %GeneratePasswordResetToken{
        user_id: uuid4(),
        expires_at: Timex.shift(Timex.now(), hours: 24)
      }

      {:error, {:not_found, :user}} = Router.dispatch(cmd)
    end

    test "with valid command" do
      account_id = uuid4()
      user_id = uuid4()
      client_id = app_id("standard", account_id)
      user_stream([%UserAdded{
        account_id: account_id,
        user_id: user_id,
        type: "managed",
        role: "developer"
      }])

      cmd = %GeneratePasswordResetToken{
        client_id: client_id,
        account_id: account_id,
        user_id: user_id,
        expires_at: Timex.shift(Timex.now(), hours: 24)
      }
      :ok = Router.dispatch(cmd)

      assert_receive_event(PasswordResetTokenGenerated, fn(event) ->
        assert event.user_id == cmd.user_id
        assert event.token
        assert event.expires_at
      end)
    end
  end

  describe "dispatch GenerateEmailVerificationToken" do
    test "with invalid command" do
      cmd = %GenerateEmailVerificationToken{}

      {:error, {:validation_failed, _}} = Router.dispatch(cmd)
    end

    test "with non existing user id" do
      cmd = %GenerateEmailVerificationToken{
        user_id: uuid4(),
        expires_at: Timex.shift(Timex.now(), hours: 24)
      }

      {:error, {:not_found, :user}} = Router.dispatch(cmd)
    end

    test "with valid command" do
      account_id = uuid4()
      client_id = app_id("standard", account_id)

      user_id = uuid4()
      user_stream([%UserAdded{
        account_id: account_id,
        user_id: user_id,
        type: "managed",
        role: "customer"
      }])

      cmd = %GenerateEmailVerificationToken{
        requester_id: user_id,
        account_id: account_id,
        client_id: client_id,
        user_id: user_id,
        expires_at: Timex.shift(Timex.now(), hours: 24)
      }
      :ok = Router.dispatch(cmd)

      assert_receive_event(EmailVerificationTokenGenerated, fn(event) ->
        assert event.user_id == cmd.user_id
        assert event.token
        assert event.expires_at
      end)
    end
  end

  describe "dispatch ChangePassword" do
    test "with invalid command" do
      cmd = %ChangePassword{}

      {:error, {:validation_failed, _}} = Router.dispatch(cmd)
    end

    test "with non existing user id" do
      cmd = %ChangePassword{
        user_id: uuid4(),
        reset_token: uuid4(),
        new_password: "test1234"
      }

      {:error, {:not_found, :user}} = Router.dispatch(cmd)
    end

    test "with valid command" do
      account_id = uuid4()
      user_id = uuid4()
      client_id = app_id("standard", account_id)
      UserTypeStore.put(user_id, "managed")

      original_password_hash = hashpwsalt("test1234")
      user_stream([%UserAdded{
        account_id: account_id,
        user_id: user_id,
        password_hash: original_password_hash,
        type: "managed",
        role: "developer"
      }])

      cmd = %ChangePassword{
        requester_id: user_id,
        account_id: account_id,
        client_id: client_id,
        user_id: user_id,
        current_password: "test1234",
        new_password: "test1234"
      }
      :ok = Router.dispatch(cmd)

      assert_receive_event(PasswordChanged, fn(event) ->
        assert event.user_id == user_id
        assert event.new_password_hash != original_password_hash
      end)
    end
  end

  describe "dispatch ChangeUserRole" do
    test "with invalid command" do
      cmd = %ChangeUserRole{}

      {:error, {:validation_failed, _}} = Router.dispatch(cmd)
    end

    test "with non existing user id" do
      cmd = %ChangeUserRole{
        user_id: uuid4(),
        account_id: uuid4(),
        role: "developer"
      }

      {:error, {:not_found, :user}} = Router.dispatch(cmd)
    end

    test "with valid command" do
      account_id = uuid4()
      requester_id = user_id(account_id, "administrator")
      client_id = app_id("standard", account_id)

      user_id = uuid4()
      user_stream([%UserAdded{
        account_id: account_id,
        user_id: user_id,
        type: "managed",
        role: "read_only"
      }])
      cmd = %ChangeUserRole{
        requester_id: requester_id,
        account_id: account_id,
        client_id: client_id,
        user_id: user_id,
        role: "developer"
      }

      :ok = Router.dispatch(cmd)

      assert_receive_event(UserRoleChanged, fn(event) ->
        assert event.user_id == cmd.user_id
        assert event.role == cmd.role
      end)
    end
  end

  describe "dispatch UpdateUserInfo" do
    test "with invalid command" do
      cmd = %UpdateUserInfo{}

      {:error, {:validation_failed, _}} = Router.dispatch(cmd)
    end

    test "with non existing user id" do
      cmd = %UpdateUserInfo{
        user_id: uuid4(),
        effective_keys: ["name"],
        name: Faker.Name.name()
      }

      {:error, {:not_found, :user}} = Router.dispatch(cmd)
    end

    test "with valid command" do
      account_id = uuid4()
      requester_id = user_id(account_id, "administrator")
      client_id = app_id("standard", account_id)

      user_id = uuid4()
      user_stream([%UserAdded{
        account_id: account_id,
        user_id: user_id,
        type: "managed",
        role: "read_only"
      }])
      cmd = %UpdateUserInfo{
        requester_id: requester_id,
        client_id: client_id,
        account_id: account_id,
        user_id: user_id,
        effective_keys: ["name"],
        name: Faker.Name.name()
      }

      :ok = Router.dispatch(cmd)

      assert_receive_event(UserInfoUpdated, fn(event) ->
        assert event.user_id == cmd.user_id
        assert event.name == cmd.name
      end)
    end
  end

  describe "dispatch VerifyEmail" do
    test "with invalid command" do
      cmd = %VerifyEmail{}

      {:error, {:validation_failed, _}} = Router.dispatch(cmd)
    end

    test "with non existing user id" do
      cmd = %VerifyEmail{
        user_id: uuid4(),
        verification_token: uuid4()
      }

      {:error, {:not_found, :user}} = Router.dispatch(cmd)
    end

    test "with valid command" do
      user_id = uuid4()
      client_id = app_id("system")

      token = uuid4()
      user_stream([
        %UserAdded{
          account_id: uuid4(),
          user_id: user_id,
          type: "standard",
          role: "owner"
        },
        %EmailVerificationTokenGenerated{
          user_id: user_id,
          token: token,
          expires_at: Timex.shift(Timex.now(), hours: 24)
        }
      ])
      cmd = %VerifyEmail{
        user_id: user_id,
        client_id: client_id,
        verification_token: token
      }

      :ok = Router.dispatch(cmd)

      assert_receive_event(EmailVerified, fn(event) ->
        assert event.user_id == cmd.user_id
      end)
    end
  end

  describe "dispatch UpdateAccountInfo" do
    test "with invalid command" do
      cmd = %UpdateAccountInfo{
        effective_keys: ["name"]
      }

      {:error, {:validation_failed, _}} = Router.dispatch(cmd)
    end

    test "with non existing account id" do
      cmd = %UpdateAccountInfo{
        account_id: uuid4(),
        effective_keys: ["name"],
        name: Faker.Company.name()
      }

      {:error, {:not_found, :account}} = Router.dispatch(cmd)
    end

    test "with valid command" do
      live_account_id = uuid4()
      test_account_id = uuid4()
      user_id = uuid4()
      client_id = app_id("standard", live_account_id)

      event1 = %AccountCreated{
        account_id: live_account_id,
        owner_id: user_id,
        mode: "live",
        test_account_id: test_account_id,
        name: Faker.Company.name(),
        default_locale: "en"
      }

      event2 = %AccountCreated{
        account_id: test_account_id,
        owner_id: user_id,
        mode: "test",
        live_account_id: live_account_id,
        name: event1.name,
        default_locale: "en"
      }

      append_to_stream("account-" <> live_account_id, [event1])
      append_to_stream("account-" <> test_account_id, [event2])

      UserRoleStore.put(user_id, live_account_id, "administrator")

      cmd = %UpdateAccountInfo{
        requester_id: user_id,
        account_id: live_account_id,
        client_id: client_id,
        effective_keys: ["name"],
        name: Faker.Company.name()
      }

      :ok = Router.dispatch(cmd)

      assert_receive_event(AccountInfoUpdated, fn(event) ->
        assert event.name == cmd.name
      end)
    end
  end

  describe "dispatch CloseAccount" do
    test "given invalid command" do
      cmd = %CloseAccount{}

      {:error, {:validation_failed, _}} = Router.dispatch(cmd)
    end

    test "given valid command" do
      account_id = uuid4()
      test_account_id = uuid4()
      requester_id = user_id(account_id, "owner")
      client_id = app_id("system")

      account_stream([
        %AccountCreated{
          account_id: account_id,
          mode: "live",
          test_account_id: test_account_id,
          default_locale: "en",
          name: Faker.Company.name(),
          owner_id: requester_id
        }
      ])

      cmd = %CloseAccount{
        requester_id: requester_id,
        client_id: client_id,
        account_id: account_id
      }
      :ok = Router.dispatch(cmd)

      assert_receive_event(AccountClosed,
        fn(event) -> event.mode == "live" end,
        fn(event) ->
          assert event.account_id == account_id
        end
      )

      assert_receive_event(AccountClosed,
        fn(event) -> event.mode == "test" end,
        fn(event) ->
          assert event.account_id == test_account_id
        end
      )
    end
  end

  describe "dispatch AddApp" do
    test "given valid command with system role" do
      cmd = %AddApp{
        requester_role: "system",
        type: "system",
        name: Faker.String.base64(12)
      }
      :ok = Router.dispatch(cmd)

      assert_receive_event(AppAdded, fn(event) ->
        assert event.name == cmd.name
        assert event.type == cmd.type
      end)
    end

    test "given valid command with requester" do
      account_id = uuid4()
      requester_id = user_id(account_id, "administrator")
      client_id = app_id("system")

      cmd = %AddApp{
        requester_id: requester_id,
        client_id: client_id,
        account_id: account_id,
        name: Faker.String.base64(12)
      }
      :ok = Router.dispatch(cmd)

      assert_receive_event(AppAdded, fn(event) ->
        assert event.name == cmd.name
        assert event.account_id == cmd.account_id
        assert event.type == cmd.type
      end)
    end
  end

  describe "dispatch DeleteApp" do
    test "given invalid command" do
      cmd = %DeleteApp{}

      {:error, {:validation_failed, _}} = Router.dispatch(cmd)
    end

    test "given valid command" do
      account_id = uuid4()
      requester_id = user_id(account_id, "administrator")
      client_id = app_id("system")
      app_id = app_id("standard", account_id)

      app_stream([%AppAdded{
        account_id: account_id,
        app_id: app_id,
        type: "standard"
      }])

      cmd = %DeleteApp{
        requester_id: requester_id,
        client_id: client_id,
        account_id: account_id,
        app_id: app_id
      }
      :ok = Router.dispatch(cmd)

      assert_receive_event(AppDeleted, fn(event) ->
        assert event.app_id == cmd.app_id
      end)
    end
  end

  describe "dispatch UpdateApp" do
    test "given invalid command" do
      cmd = %UpdateApp{}

      {:error, {:validation_failed, _}} = Router.dispatch(cmd)
    end

    test "given non existing app id" do
      cmd = %UpdateApp{
        app_id: uuid4(),
        effective_keys: ["name"],
        name: Faker.Company.name()
      }

      {:error, {:not_found, :app}} = Router.dispatch(cmd)
    end

    test "given valid command" do
      account_id = uuid4()
      requester_id = user_id(account_id, "administrator")
      client_id = app_id("system")
      app_id = app_id("standard", account_id)

      app_stream([%AppAdded{
        account_id: account_id,
        app_id: app_id,
        type: "standard"
      }])

      cmd = %UpdateApp{
        requester_id: requester_id,
        client_id: client_id,
        account_id: account_id,
        app_id: app_id,
        effective_keys: ["name"],
        name: Faker.Name.name()
      }

      :ok = Router.dispatch(cmd)

      assert_receive_event(AppUpdated, fn(event) ->
        assert event.app_id == cmd.app_id
        assert event.name == cmd.name
      end)
    end
  end
end