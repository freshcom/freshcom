defmodule FCInventory.Router.DeleteBatchTest do
  use FCBase.RouterCase

  alias FCInventory.Router
  alias FCInventory.DeleteBatch
  alias FCInventory.{BatchAdded, BatchDeleted}

  setup do
    cmd = %DeleteBatch{
      stockable_id: uuid4(),
      batch_id: uuid4()
    }

    %{cmd: cmd}
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%DeleteBatch{})
    assert length(errors) > 0
  end

  test "given non existing stock id", %{cmd: cmd} do
    assert {:error, {:not_found, :stock}} = Router.dispatch(cmd)
  end

  test "given valid command with unauthorized role", %{cmd: cmd} do
    to_streams(:stockable_id, "stock-", [
      %BatchAdded{
        stockable_id: cmd.stockable_id,
        batch_id: cmd.batch_id
      }
    ])

    assert {:error, :access_denied} = Router.dispatch(cmd)
  end

  test "given valid command with authorized role", %{cmd: cmd} do
    account_id = uuid4()
    client_id = app_id("standard", account_id)
    requester_id = user_id(account_id, "goods_specialist")

    to_streams(:stockable_id, "stock-", [
      %BatchAdded{
        stockable_id: cmd.stockable_id,
        batch_id: cmd.batch_id
      }
    ])

    cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

    assert :ok = Router.dispatch(cmd)

    assert_receive_event(BatchDeleted, fn event ->
      assert event.batch_id == cmd.batch_id
    end)
  end

  test "given valid command with system role", %{cmd: cmd} do
    to_streams(:stockable_id, "stock-", [
      %BatchAdded{
        stockable_id: cmd.stockable_id,
        batch_id: cmd.batch_id
      }
    ])

    cmd = %{cmd | requester_role: "system"}

    assert :ok = Router.dispatch(cmd)

    assert_receive_event(BatchDeleted, fn event ->
      assert event.batch_id == cmd.batch_id
    end)
  end
end
