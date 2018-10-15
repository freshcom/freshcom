defmodule FCIdentity.UsernameKeeperTest do
  use FCIdentity.UnitCase, async: true

  alias FCIdentity.UsernameKeeper
  alias FCIdentity.UsernameStore
  alias FCIdentity.{UserAdded, UserRegistered}

  describe "handle/2 for UserAdded" do
    test "when managed user is added and everything ok" do
      event = %UserAdded{
        user_id: uuid4(),
        account_id: uuid4(),
        type: "managed",
        username: Faker.String.base64(12)
      }

      :ok = UsernameKeeper.handle(event, %{})

      assert UsernameStore.exist?(event.username, event.account_id)
    end

    test "when managed user is added but username already exists" do
      existing_username = String.downcase(Faker.String.base64(12))
      account_id = uuid4()
      UsernameStore.put(existing_username, account_id)

      event = %UserAdded{
        user_id: uuid4(),
        account_id: account_id,
        type: "managed",
        username: existing_username
      }

      {:error, :username_already_exist} = UsernameKeeper.handle(event, %{})
    end
  end

  describe "handle/2 for UserRegistered" do
    test "when everything ok" do
      event = %UserRegistered{
        user_id: uuid4(),
        username: Faker.String.base64(12)
      }

      :ok = UsernameKeeper.handle(event, %{})

      assert UsernameStore.exist?(event.username)
    end

    test "when username already exists" do
      existing_username = String.downcase(Faker.String.base64(12))
      UsernameStore.put(existing_username)

      event = %UserRegistered{
        user_id: uuid4(),
        username: existing_username
      }

      {:error, :username_already_exist} = UsernameKeeper.handle(event, %{})
    end
  end
end