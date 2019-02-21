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
    StockReservationFailed
  }

  defp assert_event(event, fun) do
    assert_receive_event(event, fun, &(&1))
  end

  defp assert_event(event) do
    assert_receive_event(event, &(&1), &(&1))
  end

  setup do
    Application.ensure_all_started(:fc_inventory)

    :ok
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%AddLineItem{})
    assert length(errors) > 0
  end

  describe "given command with" do
    setup do
      movement_id = uuid4()
      to_streams(:movement_id, "stock-movement-", [
        %MovementCreated{
          movement_id: movement_id
        }
      ])

      cmd = %AddLineItem{
        movement_id: movement_id,
        stockable_id: uuid4(),
        quantity: D.new(5)
      }

      %{cmd: cmd}
    end

    test "unauthorized role", %{cmd: cmd} do
      assert {:error, :access_denied} = Router.dispatch(cmd)
    end

    test "authorized role", %{cmd: cmd} do
      account_id = uuid4()
      requester_id = user_id(account_id, "goods_specialist")
      client_id = app_id("standard", account_id)
      cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

      assert :ok = Router.dispatch(cmd)
      assert_receive_event(LineItemAdded, fn event ->
        assert event.movement_id == cmd.movement_id
      end)
    end

    test "system role", %{cmd: cmd} do
      assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

      assert_receive_event(LineItemAdded, fn event ->
        assert event.movement_id == cmd.movement_id
      end)
    end
  end

  describe "given valid and authorized command that" do
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

    @tag :focus
    test "targets stockable with zero stock", %{cmd: cmd} do
      assert :ok = Router.dispatch(cmd)

      assert_event(LineItemAdded)

      assert_event(LineItemMarked, fn event ->
        event.status == "processing"
      end)

      assert_event(MovementMarked, fn event ->
        event.status == "processing"
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
          quantity_on_hand: D.new(1)
        },
        %BatchAdded{
          stockable_id: cmd.stockable_id,
          batch_id: uuid4(),
          quantity_on_hand: D.new(2)
        }
      ])

      assert :ok = Router.dispatch(cmd)

      assert_event(LineItemAdded)

      assert_event(StockPartiallyReserved, fn event ->
        D.cmp(event.quantity_reserved, D.new(3)) == :eq &&
        map_size(event.transactions) == 2
      end)

      assert_event(LineItemMarked, fn event ->
        event.status == "partially_reserved"
      end)

      assert_event(MovementMarked, fn event ->
        event.status == "partially_reserved"
      end)
    end
  end
end
