defmodule FCInventory.CreateTransactionTest do
  use FCInventory.UnitCase, async: true

  import FCSupport.Validation
  alias FCInventory.CreateTransaction

  describe "validations" do
    test "given no source and destination is given" do
      cmd = %CreateTransaction{}

      {:error, {:validation_failed, errors}} = validate(cmd)

      assert has_error(errors, :destination_type, :required)
      assert has_error(errors, :quantity, :required)
      assert has_error(errors, :quantity, :invalid_number)
    end
  end
end
