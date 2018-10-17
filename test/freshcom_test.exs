defmodule FreshcomTest do
  use Freshcom.IntegrationCase

  describe "register_user/1" do
    test "with invalid request" do
      assert {:error, %{errors: errors}} = Freshcom.register_user(%Request{})
      assert length(errors) > 0
    end

    test "with valid request" do
      request = %Request{
        fields: %{
          name: Faker.Name.name(),
          username: Faker.Internet.user_name(),
          email: Faker.Internet.email(),
          password: Faker.String.base64(12),
          is_term_accepted: true
        }
      }

      assert {:ok, %{data: data}} = Freshcom.register_user(request)
      assert data.id
    end
  end
end