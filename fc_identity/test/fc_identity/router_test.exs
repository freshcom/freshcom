defmodule FCIdentity.RouterTest do
  use FCIdentity.RouterCase, async: true

  import Comeonin.Argon2

  alias FCIdentity.Router
  alias FCIdentity.RoleKeeper
  alias FCIdentity.{
    RegisterUser,
    DeleteUser,
    GeneratePasswordResetToken,
    ChangePassword,
    UpdateAccountInfo
  }
  alias FCIdentity.{
    AccountCreated,
    AccountInfoUpdated
  }
  alias FCIdentity.{
    UserRegistered,
    UserAdded,
    UserDeleted,
    ChangeUserRole,
    PasswordResetTokenGenerated,
    PasswordChanged,
    UserRoleChanged
  }

  def requester_id(account_id, role) do
    requester_id = uuid4()
    RoleKeeper.keep(requester_id, account_id, role)

    requester_id
  end

  def user_stream(events) do
    Enum.each(events, fn(event) ->
      append_to_stream("user-" <> event.user_id, [event])
    end)
  end

  describe "dispatch RegisterUser" do
    test "with valid command" do
      cmd = %RegisterUser{
        username: Faker.String.base64(8),
        password: Faker.String.base64(12),
        email: Faker.Internet.email(),
        is_term_accepted: true,
        name: Faker.Name.name()
      }
      :ok = Router.dispatch(cmd)

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

      assert_receive_event(UserAdded, fn(event) ->
        assert event.username == String.downcase(cmd.username)
        assert event.password_hash
        assert event.email == cmd.email
        assert event.name == cmd.name
      end)

      assert_receive_event(UserRegistered, fn(event) ->
        assert event.username == String.downcase(cmd.username)
        assert event.default_account_id
        assert event.is_term_accepted == cmd.is_term_accepted
        assert event.name == cmd.name
        assert event.email == cmd.email
      end)
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
      requester_id = requester_id(account_id, "administrator")

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
        user_id: uuid4()
      }

      {:error, {:not_found, :user}} = Router.dispatch(cmd)
    end

    test "with valid command" do
      account_id = uuid4()
      user_id = uuid4()
      user_stream([%UserAdded{
        account_id: account_id,
        user_id: user_id,
        type: "managed",
        role: "developer"
      }])

      cmd = %GeneratePasswordResetToken{
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
      requester_id = requester_id(account_id, "administrator")

      user_id = uuid4()
      user_stream([%UserAdded{
        account_id: account_id,
        user_id: user_id,
        type: "managed",
        role: "read_only"
      }])
      cmd = %ChangeUserRole{
        requester_id: requester_id,
        user_id: user_id,
        account_id: account_id,
        role: "developer"
      }

      :ok = Router.dispatch(cmd)

      assert_receive_event(UserRoleChanged, fn(event) ->
        assert event.user_id == cmd.user_id
        assert event.role == cmd.role
      end)
    end
  end

  describe "dispatch UpdateAccountInfo" do
    test "with invalid command" do
      cmd = %UpdateAccountInfo{
        effective_keys: [:name]
      }

      {:error, {:validation_failed, _}} = Router.dispatch(cmd)
    end

    test "with non existing account id" do
      cmd = %UpdateAccountInfo{
        account_id: uuid4(),
        effective_keys: [:name],
        name: Faker.Company.name()
      }

      {:error, {:not_found, :account}} = Router.dispatch(cmd)
    end

    test "with valid command" do
      live_account_id = uuid4()
      test_account_id = uuid4()
      user_id = uuid4()

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

      RoleKeeper.keep(user_id, live_account_id, "administrator")

      cmd = %UpdateAccountInfo{
        requester_id: user_id,
        account_id: live_account_id,
        effective_keys: [:name],
        name: Faker.Company.name()
      }

      :ok = Router.dispatch(cmd)

      assert_receive_event(AccountInfoUpdated, fn(event) ->
        assert event.name == cmd.name
      end)
    end
  end
end