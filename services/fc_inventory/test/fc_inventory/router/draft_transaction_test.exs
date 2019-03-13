defmodule FCInventory.Router.DraftTransactionTest do
  use FCBase.RouterCase

  alias FCInventory.Router
  alias FCInventory.DraftTransaction
  alias FCInventory.TransactionDrafted

  setup do
    cmd = %DraftTransaction{
      source_id: uuid4(),
      destination_id: uuid4(),
      quantity: Decimal.new(5)
    }

    %{cmd: cmd}
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%DraftTransaction{})
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

    assert_receive_event(TransactionDrafted, fn event ->
      assert event.name == cmd.name
    end)
  end

  test "given valid command with system role", %{cmd: cmd} do
    assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

    assert_receive_event(TransactionDrafted, fn event ->
      assert event.name == cmd.name
    end)
  end
end
