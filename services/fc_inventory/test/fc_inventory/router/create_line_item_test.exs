defmodule FCInventory.Router.CreateLineItemTest do
  use FCBase.RouterCase

  alias Decimal, as: D
  alias FCInventory.Router
  alias FCInventory.{CreateMovement, CreateLineItem}

  alias FCInventory.{
    TransactionCreated,
    LineItemCreated,
    LineItemMarked
  }

  setup do
    Application.ensure_all_started(:fc_inventory)

    cmd = %CreateLineItem{
      movement_id: uuid4(),
      stockable_id: uuid4(),
      quantity: D.new(5),
      cause_id: uuid4(),
      cause_type: 'FCSales.OrderLineItem'
    }

    %{cmd: cmd}
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%CreateMovement{})
    assert length(errors) > 0
  end

  test "given valid command with unauthorized role", %{cmd: cmd} do
    assert {:error, :access_denied} = Router.dispatch(cmd)
  end

  test "given valid command with authorized role", %{cmd: cmd} do
    account_id = uuid4()
    requester_id = user_id(account_id, "goods_specialist")
    client_id = app_id("standard", account_id)

    batch1 = %{
      id: uuid4(),
      quantity_on_hand: D.new(3),
      quantity_reserved: D.new(0),
      expires_at: nil
    }

    batch2 = %{
      id: uuid4(),
      quantity_on_hand: D.new(1),
      quantity_reserved: D.new(0),
      expires_at: nil
    }

    FCInventory.AvailableBatchStore.put(account_id, cmd.stockable_id, batch1)
    FCInventory.AvailableBatchStore.put(account_id, cmd.stockable_id, batch2)

    cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

    assert :ok = Router.dispatch(cmd)

    assert_receive_event(LineItemCreated, fn event ->
      assert event.movement_id == cmd.movement_id
    end)

    assert_receive_event(
      TransactionCreated,
      fn event -> event.source_id == batch1.id end,
      fn event ->
        assert event.source_type == "FCInventory.Batch"
        assert event.status == "drafted"
        assert D.cmp(event.quantity, batch1.quantity_on_hand)
      end
    )

    assert_receive_event(
      TransactionCreated,
      fn event -> event.source_id == batch2.id end,
      fn event ->
        assert event.source_type == "FCInventory.Batch"
        assert event.status == "drafted"
        assert D.cmp(event.quantity, batch2.quantity_on_hand)
      end
    )

    assert_receive_event(
      TransactionCreated,
      fn event -> is_nil(event.source_id) end,
      fn event ->
        assert event.status == "pending"
        assert D.cmp(event.quantity, D.new(1))
      end
    )

    assert_receive_event(LineItemMarked, fn event ->
      assert event.status == "partially_drafted"
    end)
  end

  test "given valid command with system role", %{cmd: cmd} do
    assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

    assert_receive_event(LineItemCreated, fn event ->
      assert event.movement_id == cmd.movement_id
    end)
  end
end
