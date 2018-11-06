defmodule Freshcom.IdentityTest do
  use Freshcom.IntegrationCase

  alias Freshcom.Identity

  defp register_user() do
    request = %Request{
      fields: %{
        name: Faker.Name.name(),
        username: Faker.Internet.user_name(),
        email: Faker.Internet.email(),
        password: Faker.String.base64(12),
        is_term_accepted: true
      }
    }

    {:ok, %{data: user}} = Identity.register_user(request)

    user
  end

  defp add_user(account_id) do
    request = %Request{
      account_id: account_id,
      fields: %{
        "username" => Faker.Internet.user_name(),
        "role" => "developer",
        "password" => Faker.String.base64(12)
      },
      _role_: "sysdev"
    }

    {:ok, %{data: user}} = Identity.add_user(request)

    user
  end

  describe "register_user/1" do
    test "with invalid request" do
      assert {:error, %{errors: errors}} = Identity.register_user(%Request{})
      assert length(errors) > 0
    end

    test "with valid request" do
      request = %Request{
        fields: %{
          "name" => Faker.Name.name(),
          "username" => Faker.Internet.user_name(),
          "email" => Faker.Internet.email(),
          "password" => Faker.String.base64(12),
          "is_term_accepted" => true
        }
      }

      assert {:ok, %{data: data}} = Identity.register_user(request)
      assert data.id
    end
  end

  describe "add_user/1" do
    test "with invalid request" do
      assert {:error, %{errors: errors}} = Identity.add_user(%Request{})
      assert length(errors) > 0
    end

    test "with unauthorized requester" do
      request = %Request{
        account_id: uuid4(),
        fields: %{
          "username" => Faker.Internet.user_name(),
          "role" => "developer",
          "password" => Faker.String.base64(12)
        }
      }
      assert {:error, :access_denied} = Identity.add_user(request)
    end

    test "with valid request" do
      requester = register_user()

      request = %Request{
        requester_id: requester.id,
        account_id: requester.default_account_id,
        fields: %{
          "username" => Faker.Internet.user_name(),
          "role" => "developer",
          "password" => Faker.String.base64(12)
        }
      }

      assert {:ok, %{data: data}} = Identity.add_user(request)
      assert data.id
      assert data.username == request.fields["username"]
    end
  end

  describe "update_user_info/1" do
    test "with missing identifiers" do
      assert {:error, %{errors: errors}} = Identity.update_user_info(%Request{})
      assert length(errors) > 1
    end

    test "with invalid identifiers" do
      request = %Request{identifiers: %{"id" => uuid4()}}
      assert {:error, :not_found} = Identity.update_user_info(request)
    end

    test "with unauthorize requester" do
      requester = register_user()

      request = %Request{identifiers: %{"id" => requester.id}}
      assert {:error, :access_denied} = Identity.update_user_info(request)
    end

    test "with valid request" do
      requester = register_user()

      new_name = Faker.Name.name()
      request = %Request{
        requester_id: requester.id,
        account_id: requester.default_account_id,
        identifiers: %{"id" => requester.id},
        fields: %{"name" => new_name}
      }

      assert {:ok, %{data: data}} = Identity.update_user_info(request)
      assert data.name == new_name
    end
  end

  describe "list_user/1" do
    test "with unauthorized requester" do
      request = %Request{}

      assert {:error, :access_denied} = Identity.list_user(request)
    end

    test "with valid request" do
      requester = register_user()
      add_user(requester.default_account_id)
      add_user(requester.default_account_id)

      request = %Request{
        requester_id: requester.id,
        account_id: requester.default_account_id
      }

      assert {:ok, %{data: data}} = Identity.list_user(request)
      assert length(data) == 2
    end
  end

  describe "get_user/1" do
    test "with unauthorized requester" do
      request = %Request{}

      assert {:error, :access_denied} = Identity.get_user(request)
    end

    test "with non existing user" do
      requester = register_user()
      add_user(requester.default_account_id)

      request = %Request{
        requester_id: requester.id,
        account_id: requester.default_account_id,
        identifiers: %{"id" => uuid4()}
      }

      assert {:error, :not_found} = Identity.get_user(request)
    end

    test "with valid user" do
      requester = register_user()
      user = add_user(requester.default_account_id)

      request = %Request{
        requester_id: requester.id,
        account_id: requester.default_account_id,
        identifiers: %{"id" => user.id}
      }

      assert {:ok, %{data: data}} = Identity.get_user(request)
      assert data.id == user.id
    end
  end
end