defmodule FCIdentity.UsernameKeeperTest do
  use FCIdentity.UnitCase, async: true

  alias FCIdentity.UsernameKeeper
  alias FCIdentity.UserAdded

  describe "handle/2 for UserAdded" do
    test "when standard user is added and everything ok" do
      event = %UserAdded{
        user_id: uuid4(),
        account_id: uuid4(),
        type: "standard",
        username: Faker.String.base64(12)
      }

      :ok = UsernameKeeper.handle(event, %{})

      assert UsernameKeeper.exist?(event.username)
    end

    test "when standard user is added but username already exists" do
      existing_username = String.downcase(Faker.String.base64(12))
      UsernameKeeper.keep(%{type: "standard", username: existing_username})

      event = %UserAdded{
        user_id: uuid4(),
        account_id: uuid4(),
        type: "standard",
        username: existing_username
      }

      {:error, :username_already_exist} = UsernameKeeper.handle(event, %{})
    end

    test "when managed user is added and everything ok" do
      event = %UserAdded{
        user_id: uuid4(),
        account_id: uuid4(),
        type: "managed",
        username: Faker.String.base64(12)
      }

      :ok = UsernameKeeper.handle(event, %{})

      assert UsernameKeeper.exist?(event.username, event.account_id)
    end

    test "when managed user is added but username already exists" do
      existing_username = String.downcase(Faker.String.base64(12))
      account_id = uuid4()
      UsernameKeeper.keep(%{type: "managed", account_id: account_id, username: existing_username})

      event = %UserAdded{
        user_id: uuid4(),
        account_id: account_id,
        type: "managed",
        username: existing_username
      }

      {:error, :username_already_exist} = UsernameKeeper.handle(event, %{})
    end
  end
end