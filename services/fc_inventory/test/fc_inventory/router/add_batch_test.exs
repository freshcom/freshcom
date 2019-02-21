defmodule FCInventory.Router.AddBatchTest do
  use FCBase.RouterCase

  alias Faker.Lorem
  alias Decimal, as: D
  alias FCInventory.Router
  alias FCInventory.AddBatch
  alias FCInventory.BatchAdded

  setup do
    cmd = %AddBatch{
      stockable_id: uuid4(),
      storage_id: uuid4(),
      number: Lorem.characters(12),
      quantity_on_hand: D.new(42)
    }

    %{cmd: cmd}
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%AddBatch{})
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

    assert_receive_event(BatchAdded, fn event ->
      assert event.batch_id
    end)
  end

  test "given valid command with system role", %{cmd: cmd} do
    assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

    assert_receive_event(BatchAdded, fn event ->
      assert event.number == cmd.number
    end)
  end
end
