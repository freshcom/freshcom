defmodule FCInventory.Router.CreateMovementTest do
  use FCBase.RouterCase

  alias Decimal, as: D
  alias FCInventory.Router
  alias FCInventory.CreateMovement
  alias FCInventory.{
    BatchAdded,
    MovementCreated,
    MovementMarked
  }
  alias FCInventory.LineItem

  setup do
    Application.ensure_all_started(:fc_inventory)

    :ok
  end

  test "dispatch invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%CreateMovement{})
    assert length(errors) > 0
  end

  describe "dispatch command with" do
    setup do
      cmd = %CreateMovement{
        source_id: uuid4(),
        source_type: 'FCInventory.Storage'
      }

      %{cmd: cmd}
    end

    test "unauthorized role", %{cmd: cmd} do
      assert {:error, :access_denied} = Router.dispatch(cmd)
    end

    test "authorized role", %{cmd: cmd} do
      assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

      assert_receive_event(MovementCreated, fn event ->
        assert event.source_type == cmd.source_type
      end)
    end

    test "system role", %{cmd: cmd} do
      assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

      assert_receive_event(MovementCreated, fn event ->
        assert event.source_type == cmd.source_type
      end)
    end
  end

  describe "dispatch valid and authorized command where" do
    setup do
      s1_id = uuid4()
      s2_id = uuid4()
      li1_id = uuid4()
      li2_id = uuid4()

      cmd = %CreateMovement{
        requester_role: "system",
        account_id: uuid4(),
        source_id: uuid4(),
        source_type: "FCInventory.Storage",
        line_items: %{
          li1_id => %LineItem{stockable_id: s1_id, quantity: D.new(5)},
          li2_id => %LineItem{stockable_id: s2_id, quantity: D.new(3)}
        }
      }

      %{cmd: cmd, li1_id: li1_id, li2_id: li2_id, s1_id: s1_id, s2_id: s2_id}
    end

    test "all of the line item targets stockable that have zero stock", context do
      assert :ok = Router.dispatch(context[:cmd])

      assert_receive_event(MovementCreated, fn event ->
        assert event.source_type == context[:cmd].source_type
      end)

      # assert_receive_event(
      #   StockReservationFailed,
      #   fn event -> event.line_item_id == context[:li1_id] end,
      #   fn event ->
      #     assert event.stockable_id == context[:s1_id]
      #   end
      # )

      # assert_receive_event(
      #   StockReservationFailed,
      #   fn event -> event.line_item_id == context[:li2_id] end,
      #   fn event ->
      #     assert event.stockable_id == context[:s2_id]
      #   end
      # )

      # assert_receive_event(
      #   LineItemMarked,
      #   fn event -> event.line_item_id == context[:li1_id] end,
      #   fn event ->
      #     assert event.status == "none_reserved"
      #   end
      # )

      # assert_receive_event(
      #   LineItemMarked,
      #   fn event -> event.line_item_id == context[:li2_id] end,
      #   fn event ->
      #     assert event.status == "none_reserved"
      #   end
      # )

      assert_receive_event(
        MovementMarked,
        fn event -> event.status == "none_reserved" end,
        fn event ->
          assert event.movement_id
        end
      )
    end

    test "some of the line item targets stockable that have zero stock", context do
      to_streams(:stockable_id, "stock-", [
        %BatchAdded{
          stockable_id: context[:s1_id],
          batch_id: uuid4(),
          quantity_on_hand: D.new(2)
        },
        %BatchAdded{
          stockable_id: context[:s1_id],
          batch_id: uuid4(),
          quantity_on_hand: D.new(3)
        }
      ])

      assert :ok = Router.dispatch(context[:cmd])

      assert_receive_event(MovementCreated, fn event ->
        assert event.source_type == context[:cmd].source_type
      end)

      assert_receive_event(
        MovementMarked,
        fn event -> event.status == "partially_reserved" end,
        fn event ->
          assert event.movement_id
        end
      )
    end

    test "all of the line item targets stockable that have enough stock", context do
      to_streams(:stockable_id, "stock-", [
        %BatchAdded{
          stockable_id: context[:s1_id],
          batch_id: uuid4(),
          quantity_on_hand: D.new(3)
        },
        %BatchAdded{
          stockable_id: context[:s1_id],
          batch_id: uuid4(),
          quantity_on_hand: D.new(2)
        },
        %BatchAdded{
          stockable_id: context[:s2_id],
          batch_id: uuid4(),
          quantity_on_hand: D.new(5)
        }
      ])

      assert :ok = Router.dispatch(context[:cmd])

      assert_receive_event(MovementCreated, fn event ->
        assert event.source_type == context[:cmd].source_type
      end)

      assert_receive_event(
        MovementMarked,
        fn event -> event.status == "reserved" end,
        fn event ->
          assert event.movement_id
        end
      )
    end
  end
end
