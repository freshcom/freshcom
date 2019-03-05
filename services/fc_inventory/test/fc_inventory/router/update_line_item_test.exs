defmodule FCInventory.Router.UpdateLineItemTest do
  use FCBase.RouterCase

  alias Decimal, as: D
  alias FCInventory.Router
  alias FCInventory.UpdateLineItem

  alias FCInventory.{
    MovementCreated,
    MovementMarked,
    LineItemAdded,
    LineItemMarked,
    LineItemUpdated,
    BatchAdded,
    StockPartiallyReserved,
    StockReserved,
    StockReservationFailed,
    StockReservationCancelled,
    StockReservationDecreased
  }

  alias FCInventory.LineItem

  setup do
    Application.ensure_all_started(:fc_inventory)

    :ok
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%UpdateLineItem{})
    assert length(errors) > 0
  end

  describe "given valid command that" do
    setup do
      movement_id = uuid4()
      stockable_id = uuid4()
      to_streams(:movement_id, "stock-movement-", [
        %MovementCreated{
          movement_id: movement_id,
          status: "pending",
          line_items: %{
            stockable_id => %LineItem{quantity: D.new(5)}
          }
        }
      ])

      cmd = %UpdateLineItem{
        requester_role: "system",
        movement_id: movement_id,
        stockable_id: stockable_id
      }

      %{cmd: cmd}
    end

    @tag :focus
    test "decrease the quantity", %{cmd: cmd} do
      to_streams(:stockable_id, "stock-", [
        %BatchAdded{
          stockable_id: cmd.stockable_id,
          batch_id: uuid4(),
          status: "active",
          quantity_on_hand: D.new(15)
        }
      ])

      cmd = %{
        cmd
        | effective_keys: [:quantity],
          quantity: D.new(2)
      }

      assert :ok = Router.dispatch(cmd)

      assert_event(LineItemUpdated)

      assert_event(StockReservationDecreased, fn event ->
        D.cmp(event.quantity, D.new(3)) == :eq
      end)

      # assert_event(StockReservationFailed, fn event ->
      #   assert event.movement_id == cmd.movement_id
      # end)

      # assert_event(LineItemMarked, fn event ->
      #   event.status == "none_reserved"
      # end)

      # assert_event(MovementMarked, fn event ->
      #   event.status == "none_reserved"
      # end)
    end

    # test "targets stockable with insufficient stock", %{cmd: cmd} do
    #   to_streams(:stockable_id, "stock-", [
    #     %BatchAdded{
    #       stockable_id: cmd.stockable_id,
    #       batch_id: uuid4(),
    #       quantity_on_hand: D.new(1)
    #     },
    #     %BatchAdded{
    #       stockable_id: cmd.stockable_id,
    #       batch_id: uuid4(),
    #       quantity_on_hand: D.new(2)
    #     }
    #   ])

    #   assert :ok = Router.dispatch(cmd)

    #   assert_event(LineItemAdded)

    #   assert_event(StockPartiallyReserved, fn event ->
    #     D.cmp(event.quantity_reserved, D.new(3)) == :eq &&
    #     map_size(event.transactions) == 2
    #   end)

    #   assert_event(LineItemMarked, fn event ->
    #     event.status == "partially_reserved"
    #   end)

    #   assert_event(MovementMarked, fn event ->
    #     event.status == "partially_reserved"
    #   end)
    # end

    # test "targets stockable with sufficient stock", %{cmd: cmd} do
    #   to_streams(:stockable_id, "stock-", [
    #     %BatchAdded{
    #       stockable_id: cmd.stockable_id,
    #       batch_id: uuid4(),
    #       quantity_on_hand: D.new(3)
    #     },
    #     %BatchAdded{
    #       stockable_id: cmd.stockable_id,
    #       batch_id: uuid4(),
    #       quantity_on_hand: D.new(2)
    #     }
    #   ])

    #   assert :ok = Router.dispatch(cmd)

    #   assert_event(LineItemAdded)

    #   assert_event(StockReserved, fn event ->
    #     D.cmp(event.quantity, D.new(5)) == :eq &&
    #     map_size(event.transactions) == 2
    #   end)

    #   assert_event(LineItemMarked, fn event ->
    #     event.status == "reserved"
    #   end)

    #   assert_event(MovementMarked, fn event ->
    #     event.status == "reserved"
    #   end)
    # end
  end
end
