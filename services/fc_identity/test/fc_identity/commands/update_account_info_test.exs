defmodule FCIdentity.UpdateAccountInfoTest do
  use FCIdentity.UnitCase, async: true

  import FCSupport.Validation
  alias FCIdentity.AccountAliasStore
  alias FCIdentity.UpdateAccountInfo

  describe "validations" do
    test "given existing alias" do
      AccountAliasStore.put("roy", uuid4())
      cmd = %UpdateAccountInfo{
        account_id: uuid4(),
        effective_keys: ["alias"],
        alias: "roy"
      }

      {:error, {:validation_failed, errors}} = validate(cmd, effective_keys: [:alias])

      assert has_error(errors, :alias, :taken)
    end
  end
end