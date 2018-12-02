defmodule FCIdentity.UpdateAccountInfoTest do
  use FCIdentity.UnitCase, async: true

  import FCSupport.Validation
  alias FCIdentity.AccountHandleStore
  alias FCIdentity.UpdateAccountInfo

  describe "validations" do
    test "given existing handle" do
      AccountHandleStore.put("roy", uuid4())
      cmd = %UpdateAccountInfo{
        account_id: uuid4(),
        effective_keys: ["handle"],
        handle: "roy"
      }

      {:error, {:validation_failed, errors}} = validate(cmd, effective_keys: [:handle])

      assert has_error(errors, :handle, :taken)
    end
  end
end