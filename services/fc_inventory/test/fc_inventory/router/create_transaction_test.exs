defmodule FCInventory.Router.CreateTransactionTest do
  use FCBase.RouterCase

  alias Decimal, as: D
  alias FCInventory.Router
  alias FCInventory.CreateTransaction
  alias FCInventory.TransactionCreated

  setup do
    cmd = %CreateTransaction{
      source_stockable_id: uuid4(),
      destination_id: uuid4(),
      destination_type: 'FCInventory.Batch',
      quantity: D.new(1)
    }

    %{cmd: cmd}
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%CreateTransaction{})
    assert length(errors) > 0
  end

  test "given valid command with unauthorized role", %{cmd: cmd} do
    assert {:error, :access_denied} = Router.dispatch(cmd)
  end

  test "given valid command with authorized role", %{cmd: cmd} do
    account_id = uuid4()
    requester_id = user_id(account_id, "goods_specialist")
    client_id = app_id("standard", account_id)

    cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

    assert :ok = Router.dispatch(cmd)

    assert_receive_event(TransactionCreated, fn event ->
      assert event.quantity == "#{cmd.quantity}"
    end)
  end

  test "given valid command with system role", %{cmd: cmd} do
    assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

    assert_receive_event(TransactionCreated, fn event ->
      assert event.quantity == "#{cmd.quantity}"
    end)
  end
end
