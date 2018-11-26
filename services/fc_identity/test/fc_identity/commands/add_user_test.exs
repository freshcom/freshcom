defmodule FCIdentity.AddUserTest do
  use FCIdentity.UnitCase, async: true

  import FCSupport.Validation
  alias FCIdentity.UsernameStore
  alias FCIdentity.AddUser

  describe "validations" do
    test "given existing username" do
      account_id = uuid4()
      UsernameStore.put("roy", uuid4(), account_id)
      cmd = %AddUser{
        user_id: uuid4(),
        account_id: account_id,
        username: "ROy"
      }

      {:error, {:validation_failed, errors}} = validate(cmd)

      assert has_error(errors, :username, :taken)
    end

    test "given invalid email" do
      cmd = %AddUser{
        email: "test"
      }

      {:error, {:validation_failed, errors}} = validate(cmd)

      assert has_error(errors, :email, :invalid_format)
    end
  end
end