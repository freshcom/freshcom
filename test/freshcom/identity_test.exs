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
      user = register_user()

      request = %Request{identifiers: %{"id" => user.id}}
      assert {:error, :access_denied} = Identity.update_user_info(request)
    end

    @tag :focus
    test "with valid request" do
      user = register_user()

      new_name = Faker.Name.name()
      request = %Request{
        requester: %{id: user.id, account_id: user.default_account_id},
        identifiers: %{"id" => user.id},
        fields: %{"name" => new_name}
      }

      assert {:ok, %{data: data}} = Identity.update_user_info(request)
      assert data.name == new_name
    end
  end
end