defmodule FCInventory.Router.AddLineItemTest do
  use FCBase.RouterCase

  alias Decimal, as: D
  alias FCInventory.Router
  alias FCInventory.AddLineItem

  alias FCInventory.{
    MovementCreated,
    MovementMarked,
    LineItemAdded,
    LineItemMarked,
    BatchAdded,
    StockPartiallyReserved,
    StockReserved,
    StockReservationFailed
  }

  setup do
    Application.ensure_all_started(:fc_inventory)

    :ok
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%AddLineItem{})
    assert length(errors) > 0
  end

  describe "given valid command that" do
    setup do
      movement_id = uuid4()
      to_streams(:movement_id, "stock-movement-", [
        %MovementCreated{
          movement_id: movement_id,
          status: "pending"
        }
      ])

      cmd = %AddLineItem{
        requester_role: "system",
        movement_id: movement_id,
        stockable_id: uuid4(),
        quantity: D.new(5)
      }

      %{cmd: cmd}
    end

    test "targets stockable with zero stock", %{cmd: cmd} do
      assert :ok = Router.dispatch(cmd)

      assert_event(LineItemAdded)

      assert_event(LineItemMarked, fn event ->
        event.status == "reserving"
      end)

      assert_event(MovementMarked, fn event ->
        event.status == "reserving"
      end)

      assert_event(StockReservationFailed, fn event ->
        assert event.movement_id == cmd.movement_id
      end)

      assert_event(LineItemMarked, fn event ->
        event.status == "none_reserved"
      end)

      assert_event(MovementMarked, fn event ->
        event.status == "none_reserved"
      end)
    end

    test "targets stockable with insufficient stock", %{cmd: cmd} do
      to_streams(:stockable_id, "stock-", [
        %BatchAdded{
          stockable_id: cmd.stockable_id,
          batch_id: uuid4(),
          status: "active",
          quantity_on_hand: D.new(1)
        },
        %BatchAdded{
          stockable_id: cmd.stockable_id,
          batch_id: uuid4(),
          status: "active",
          quantity_on_hand: D.new(2)
        }
      ])

      assert :ok = Router.dispatch(cmd)

      assert_event(LineItemAdded)

      assert_event(LineItemMarked, fn event ->
        event.status == "reserving"
      end)

      assert_event(MovementMarked, fn event ->
        event.status == "reserving"
      end)

      assert_event(StockPartiallyReserved, fn event ->
        D.cmp(event.quantity_reserved, D.new(3)) == :eq
      end)

      assert_event(LineItemMarked, fn event ->
        event.status == "partially_reserved"
      end)

      assert_event(MovementMarked, fn event ->
        event.status == "partially_reserved"
      end)
    end

    test "targets stockable with sufficient stock", %{cmd: cmd} do
      to_streams(:stockable_id, "stock-", [
        %BatchAdded{
          stockable_id: cmd.stockable_id,
          batch_id: uuid4(),
          status: "active",
          quantity_on_hand: D.new(3)
        },
        %BatchAdded{
          stockable_id: cmd.stockable_id,
          batch_id: uuid4(),
          status: "active",
          quantity_on_hand: D.new(2)
        }
      ])

      assert :ok = Router.dispatch(cmd)

      assert_event(LineItemAdded)

      assert_event(LineItemMarked, fn event ->
        event.status == "reserving"
      end)

      assert_event(MovementMarked, fn event ->
        event.status == "reserving"
      end)

      assert_event(StockReserved, fn event ->
        D.cmp(event.quantity, D.new(5)) == :eq
      end)

      assert_event(LineItemMarked, fn event ->
        event.status == "reserved"
      end)

      assert_event(MovementMarked, fn event ->
        event.status == "reserved"
      end)
    end
  end
end
