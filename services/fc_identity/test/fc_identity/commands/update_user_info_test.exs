defmodule FCIdentity.UpdateUserInfoTest do
  use FCIdentity.UnitCase, async: true

  import FCSupport.Validation
  alias FCIdentity.UsernameStore
  alias FCIdentity.UpdateUserInfo

  describe "validations" do
    test "given existing username" do
      account_id = uuid4()
      UsernameStore.put("roy", account_id)
      cmd = %UpdateUserInfo{
        user_id: uuid4(),
        account_id: account_id,
        effective_keys: ["username"],
        username: "roy"
      }

      {:error, {:validation_failed, errors}} = validate(cmd)

      assert has_error(errors, :username, :taken)
    end
  end
end