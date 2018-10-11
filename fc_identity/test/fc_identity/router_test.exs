defmodule FCIdentity.RouterTest do
  use FCIdentity.RouterCase, async: true

  alias FCIdentity.Router
  alias FCIdentity.RoleKeeper
  alias FCIdentity.{RegisterUser, DeleteUser, UpdateAccountInfo}
  alias FCIdentity.{AccountCreated, AccountInfoUpdated}
  alias FCIdentity.{UserRegistered, UserAdded, UserDeleted}

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
      requester_id = uuid4()
      account_id = uuid4()
      RoleKeeper.keep(requester_id, account_id, "administrator")

      user_id = uuid4()
      event1 = %UserAdded{
        account_id: account_id,
        user_id: user_id,
        type: "managed",
        role: "developer"
      }
      append_to_stream("user-" <> user_id, [event1])

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