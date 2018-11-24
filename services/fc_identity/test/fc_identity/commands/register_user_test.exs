defmodule FCIdentity.RegisterUserTest do
  use FCIdentity.UnitCase, async: true

  import FCSupport.Validation
  alias FCIdentity.UsernameStore
  alias FCIdentity.RegisterUser

  describe "validations" do
    test "given existing username" do
      UsernameStore.put("roy")
      cmd = %RegisterUser{username: "roy"}

      {:error, {:validation_failed, errors}} = validate(cmd)

      assert has_error(errors, :username, :taken)
    end
  end
end