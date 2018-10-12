defmodule FCIdentity.ChangePasswordTest do
  use FCIdentity.UnitCase, async: true

  import FCIdentity.Validation
  alias FCIdentity.ChangePassword

  describe "validations" do
    test "when requester id not provided" do
      {:error, {:validation_failed, errors}} = validate(%ChangePassword{})

      refute has_error(errors, :current_password, :required)
      assert has_error(errors, :reset_token, :required)
      assert has_error(errors, :new_password, :required)
    end

    test "when requester id is same as user id" do
      requester_id = uuid4()
      cmd = %ChangePassword{requester_id: requester_id, user_id: requester_id}

      {:error, {:validation_failed, errors}} = validate(cmd)

      refute has_error(errors, :reset_token, :required)
      assert has_error(errors, :current_password, :required)
      assert has_error(errors, :new_password, :required)
    end

    test "when requester id is not the same as user id" do
      cmd = %ChangePassword{
        requester_id: uuid4(),
        user_id: uuid4(),
        new_password: Faker.String.base64(12)
      }

      assert {:ok, _} = validate(cmd)
    end
  end
end