defmodule FCIdentity.AddAppTest do
  use FCIdentity.UnitCase, async: true

  import FCSupport.Validation
  alias FCIdentity.AddApp

  describe "validations" do
    test "given type is standard" do
      cmd = %AddApp{
        type: "standard"
      }

      {:error, {:validation_failed, errors}} = validate(cmd)

      assert has_error(errors, :account_id, :required)
      assert has_error(errors, :name, :required)
    end

    test "given type is system" do
      cmd = %AddApp{
        type: "system"
      }

      {:error, {:validation_failed, errors}} = validate(cmd)

      refute has_error(errors, :account_id, :required)
      assert has_error(errors, :name, :required)
    end
  end
end
