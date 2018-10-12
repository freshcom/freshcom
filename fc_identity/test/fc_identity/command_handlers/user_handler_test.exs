defmodule FCIdentity.UserHandlerTest do
  use FCIdentity.UnitCase, async: true

  import Comeonin.Argon2

  alias FCIdentity.UsernameKeeper
  alias FCIdentity.UserHandler
  alias FCIdentity.User
  alias FCIdentity.{AddUser, ChangePassword}
  alias FCIdentity.{UserAdded, PasswordChanged}

  describe "handle AddUser" do
    setup do
      %{cmd: %AddUser{requester_role: "sysdev"}}
    end

    test "when requester is not permitted" do
      cmd = %AddUser{requester_role: "customer"}

      {:error, :access_denied} = UserHandler.handle(%User{}, cmd)
    end

    test "when none of first name, last name or name is given should return validation error", %{cmd: cmd} do
      {:error, {:validation_failed, errors}} = UserHandler.handle(%User{}, cmd)

      assert has_error(errors, :name, :required)
    end

    test "when first name is given should return event", %{cmd: cmd} do
      cmd = %{cmd | first_name: Faker.Name.first_name()}
      %UserAdded{name: name} = UserHandler.handle(%User{}, cmd)
      assert name == cmd.first_name
    end

    test "when last name is given should return event", %{cmd: cmd} do
      cmd = %{cmd | last_name: Faker.Name.last_name()}
      %UserAdded{name: name} = UserHandler.handle(%User{}, cmd)
      assert name == cmd.last_name
    end

    test "when name is given should return event", %{cmd: cmd} do
      cmd = %{cmd | name: Faker.Name.name()}
      %UserAdded{name: name} = UserHandler.handle(%User{}, cmd)
      assert name == cmd.name
    end

    test "when string with extra leading and trailing space given", %{cmd: cmd} do
      cmd = %{cmd | email: "  roY@ExAmPle.cOm      ", name: "test"}
      %UserAdded{email: email} = UserHandler.handle(%User{}, cmd)
      assert email == "roy@example.com"
    end

    test "when given existing username", %{cmd: cmd} do
      username = String.downcase(Faker.String.base64(12))
      UsernameKeeper.keep(%{type: "standard", username: username})

      cmd = %{cmd | name: Faker.Name.name(), username: username}
      {:error, {:validation_failed, errors}} = UserHandler.handle(%User{}, cmd)
      assert has_error(errors, :username, :already_exist)
    end

    test "when no password given password_hash should be nil", %{cmd: cmd} do
      cmd = %{cmd | name: Faker.Name.name()}
      %UserAdded{password_hash: password_hash} = UserHandler.handle(%User{}, cmd)
      assert is_nil(password_hash)
    end

    test "when password given password_hash should be populated", %{cmd: cmd} do
      cmd = %{cmd | name: Faker.Name.name(), password: Faker.Lorem.sentence(1)}
      %UserAdded{password_hash: password_hash} = UserHandler.handle(%User{}, cmd)
      assert password_hash
    end

    test "when all fields are valid", %{cmd: cmd} do
      cmd = %{cmd |
        user_id: uuid4(),
        account_id: uuid4(),
        username: Faker.String.base64(8),
        email: Faker.Internet.email(),
        name: Faker.Name.name(),
        password: Faker.Lorem.sentence(1)
      }

      event = %UserAdded{} = UserHandler.handle(%User{}, cmd)

      assert event.user_id == cmd.user_id
      assert event.account_id == cmd.account_id
      assert event.username == String.downcase(cmd.username)
      assert event.email == cmd.email
    end
  end

  describe "handle ChangePassword" do
    test "when changing user's own password with invalid current password" do
      state = %User{
        id: uuid4(),
        password_hash: hashpwsalt("test1234"),
      }
      cmd = %ChangePassword{
        requester_id: state.id,
        user_id: state.id,
        current_password: "invalid",
        new_password: "test1234"
      }
      {:error, {:validation_failed, errors}} = UserHandler.handle(state, cmd)

      assert has_error(errors, :current_password, :invalid)
    end

    test "when changing user's own password and current password is valid" do
      state = %User{
        id: uuid4(),
        password_hash: hashpwsalt("test1234"),
      }
      cmd = %ChangePassword{
        requester_id: state.id,
        user_id: state.id,
        current_password: "test1234",
        new_password: "test1234"
      }

      event = UserHandler.handle(state, cmd)

      assert %PasswordChanged{} = event
      assert event.new_password_hash
    end

    test "when resetting password but reset token provided is invalid" do
      state = %User{
        id: uuid4(),
        password_reset_token: uuid4(),
        password_reset_token_expires_at: Timex.shift(Timex.now(), hours: 24)
      }
      cmd = %ChangePassword{
        user_id: state.id,
        reset_token: "invalid",
        new_password: "test1234"
      }
      {:error, {:validation_failed, errors}} = UserHandler.handle(state, cmd)

      assert has_error(errors, :reset_token, :invalid)
    end

    test "when reset token provided has expired" do
      state = %User{
        id: uuid4(),
        password_reset_token: uuid4(),
        password_reset_token_expires_at: Timex.shift(Timex.now(), hours: -24),
      }
      cmd = %ChangePassword{
        user_id: state.id,
        reset_token: state.password_reset_token,
        new_password: "test1234"
      }
      {:error, {:validation_failed, errors}} = UserHandler.handle(state, cmd)

      assert has_error(errors, :reset_token, :expired)
    end

    test "when valid reset token provided" do
      state = %User{
        id: uuid4(),
        password_reset_token: uuid4(),
        password_reset_token_expires_at: Timex.shift(Timex.now(), hours: 24),
      }
      cmd = %ChangePassword{
        user_id: state.id,
        reset_token: state.password_reset_token,
        new_password: "test1234"
      }

      event = UserHandler.handle(state, cmd)

      assert %PasswordChanged{} = event
      assert event.new_password_hash
    end

    test "when changing password of a user in the same account with invalid role" do
      state = %User{
        id: uuid4(),
        account_id: uuid4(),
        password_hash: hashpwsalt("test1234"),
      }
      cmd = %ChangePassword{
        requester_id: uuid4(),
        requester_role: "customer",
        account_id: state.account_id,
        user_id: state.id,
        new_password: "test1234"
      }

      assert {:error, :access_denied} = UserHandler.handle(state, cmd)
    end

    test "when changing password of a user in a different account" do
      state = %User{
        id: uuid4(),
        account_id: uuid4(),
        password_hash: hashpwsalt("test1234"),
      }
      cmd = %ChangePassword{
        requester_id: uuid4(),
        requester_role: "administrator",
        account_id: uuid4(),
        user_id: state.id,
        new_password: "test1234"
      }

      assert {:error, :access_denied} = UserHandler.handle(state, cmd)
    end

    test "when changing password for owner" do
      state = %User{
        id: uuid4(),
        role: "owner",
        account_id: uuid4(),
        password_hash: hashpwsalt("test1234"),
      }
      cmd = %ChangePassword{
        requester_id: uuid4(),
        requester_role: "administrator",
        account_id: state.account_id,
        user_id: state.id,
        new_password: "test1234"
      }

      {:error, :access_denied} = UserHandler.handle(state, cmd)
    end

    test "when changing password of a user in the same account with valid role" do
      state = %User{
        id: uuid4(),
        account_id: uuid4(),
        password_hash: hashpwsalt("test1234"),
      }
      cmd = %ChangePassword{
        requester_id: uuid4(),
        requester_role: "administrator",
        account_id: state.account_id,
        user_id: state.id,
        new_password: "test1234"
      }

      event = UserHandler.handle(state, cmd)

      assert %PasswordChanged{} = event
      assert event.new_password_hash
    end
  end
end