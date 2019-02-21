defmodule FCInventory.Router.UpdateBatchTest do
  use FCBase.RouterCase

  alias Decimal, as: D
  alias FCInventory.Router
  alias FCInventory.UpdateBatch
  alias FCInventory.{BatchAdded, BatchUpdated}

  setup do
    cmd = %UpdateBatch{
      stockable_id: uuid4(),
      batch_id: uuid4(),
      effective_keys: [:quantity_on_hand],
      quantity_on_hand: D.new(5)
    }

    %{cmd: cmd}
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%UpdateBatch{})
    assert length(errors) > 0
  end

  test "given valid command with authorized role", %{cmd: cmd} do
    account_id = uuid4()
    client_id = app_id("standard", account_id)
    requester_id = user_id(account_id, "goods_specialist")

    to_streams(:stockable_id, "stock-", [
      %BatchAdded{
        stockable_id: cmd.stockable_id,
        batch_id: cmd.batch_id,
        quantity_on_hand: D.new(1)
      }
    ])

    cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

    assert :ok = Router.dispatch(cmd)

    assert_receive_event(BatchUpdated, fn event ->
      assert D.cmp(event.quantity_on_hand, cmd.quantity_on_hand)
    end)
  end
end
