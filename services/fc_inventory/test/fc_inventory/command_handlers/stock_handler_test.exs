defmodule FCInventory.StockHandlerTest do
  use FCInventory.UnitCase, async: true

  alias Decimal, as: D
  alias FCInventory.{
    AddBatch,
    UpdateBatch,
    DeleteBatch,
    ReserveStock
  }
  alias FCInventory.{
    BatchAdded,
    BatchUpdated,
    BatchDeleted,
    StockReservationFailed,
    StockPartiallyReserved,
    StockReserved
  }
  alias FCInventory.{Stock, Batch, StockHandler}

  setup do
    state = %Stock{id: uuid4(), account_id: uuid4()}

    %{state: state}
  end

  describe "handle AddBatch" do
    test "when command is not authorized" do
      cmd = %AddBatch{}
      state = %Stock{}

      assert {:error, :access_denied} = StockHandler.handle(state, cmd)
    end

    test "when valid command" do
      cmd = %AddBatch{
        requester_role: "sysdev",
        account_id: uuid4(),
        stockable_id: uuid4(),
        quantity_on_hand: D.new(8)
      }
      state = %Stock{}

      assert event = StockHandler.handle(state, cmd)
      assert %BatchAdded{} = event
      assert event.batch_id
      assert event.requester_role == cmd.requester_role
      assert event.account_id == cmd.account_id
      assert event.stockable_id == cmd.stockable_id
      assert event.quantity_on_hand == cmd.quantity_on_hand
    end
  end

  describe "handle UpdateBatch" do
    setup do
      cmd = %UpdateBatch{
        requester_role: "sysdev",
        account_id: uuid4(),
        stockable_id: uuid4(),
        batch_id: uuid4(),
        effective_keys: [:quantity_on_hand, :description],
        locale: "zh-CN",
        quantity_on_hand: D.new(8),
        description: "上等货色"
      }

      %{cmd: cmd}
    end

    test "when state has no id" do
      cmd = %UpdateBatch{}
      state = %Stock{}

      assert {:error, {:not_found, :stock}} = StockHandler.handle(state, cmd)
    end

    test "when command is not authorized", %{state: state} do
      cmd = %UpdateBatch{}

      assert {:error, :access_denied} = StockHandler.handle(state, cmd)
    end

    test "when state does not have target batch", %{cmd: cmd, state: state} do
      assert {:error, {:not_found, :batch}} = StockHandler.handle(state, cmd)
    end

    test "when state have target batch", %{cmd: cmd, state: state} do
      state = %{state | batches: %{cmd.batch_id => %Batch{}}}

      assert event = StockHandler.handle(state, cmd)
      assert %BatchUpdated{} = event
      assert event.quantity_on_hand == cmd.quantity_on_hand
      assert event.translations["zh-CN"]["description"] == cmd.description
      assert event.effective_keys == [:quantity_on_hand, :translations]
      assert event.original_fields[:quantity_on_hand] == state.batches[cmd.batch_id].quantity_on_hand
      assert event.original_fields[:translations] == state.batches[cmd.batch_id].translations
      assert event.requester_role == cmd.requester_role
      assert event.account_id == cmd.account_id
      assert event.stockable_id == cmd.stockable_id
      assert event.batch_id == cmd.batch_id
    end
  end

  describe "handle DeleteBatch" do
    setup do
      cmd = %DeleteBatch{
        requester_role: "sysdev",
        account_id: uuid4(),
        stockable_id: uuid4(),
        batch_id: uuid4()
      }

      %{cmd: cmd}
    end

    test "when state has no id" do
      cmd = %DeleteBatch{}
      state = %Stock{}

      assert {:error, {:not_found, :stock}} = StockHandler.handle(state, cmd)
    end

    test "when command is not authorized", %{state: state} do
      cmd = %DeleteBatch{}

      assert {:error, :access_denied} = StockHandler.handle(state, cmd)
    end

    test "when state does not have target batch", %{cmd: cmd, state: state} do
      assert {:error, {:not_found, :batch}} = StockHandler.handle(state, cmd)
    end

    test "when state have target batch", %{cmd: cmd, state: state} do
      state = %{state | batches: %{cmd.batch_id => %Batch{}}}

      assert event = StockHandler.handle(state, cmd)
      assert %BatchDeleted{} = event
      assert event.requester_role == cmd.requester_role
      assert event.account_id == cmd.account_id
      assert event.stockable_id == cmd.stockable_id
      assert event.batch_id == cmd.batch_id
    end
  end

  describe "handle ReserveStock" do
    setup do
      cmd = %ReserveStock{
        requester_role: "system",
        account_id: uuid4(),
        movement_id: uuid4(),
        stockable_id: uuid4(),
        line_item_id: uuid4(),
        quantity: D.new(5)
      }

      %{cmd: cmd}
    end

    test "when command is not authorized", %{state: state} do
      cmd = %AddBatch{}

      assert {:error, :access_denied} = StockHandler.handle(state, cmd)
    end

    test "when state has no batch", %{cmd: cmd, state: state} do
      assert event = StockHandler.handle(state, cmd)
      assert %StockReservationFailed{} = event
      assert event.account_id == cmd.account_id
      assert event.stockable_id == cmd.stockable_id
      assert event.movement_id == cmd.movement_id
      assert event.line_item_id == cmd.line_item_id
      assert event.quantity == cmd.quantity
    end

    test "when state have batches but not enough for reservation", %{cmd: cmd, state: state} do
      state = %{
        state
        | batches: %{
          uuid4() => %Batch{quantity_on_hand: D.new(5), quantity_reserved: D.new(2)},
          uuid4() => %Batch{quantity_on_hand: D.new(8), quantity_reserved: D.new(7)}
        }
      }

      assert event = StockHandler.handle(state, cmd)
      assert %StockPartiallyReserved{transactions: transactions} = event
      assert D.cmp(event.quantity_target, cmd.quantity) == :eq
      assert D.cmp(event.quantity_reserved, D.new(4)) == :eq
      assert event.account_id == cmd.account_id
      assert event.stockable_id == cmd.stockable_id
      assert event.movement_id == cmd.movement_id
      assert event.line_item_id == cmd.line_item_id
      assert map_size(transactions) == 2
    end

    test "when state have batches enough for the reservation", %{cmd: cmd, state: state} do
      state = %{
        state
        | batches: %{
          uuid4() => %Batch{quantity_on_hand: D.new(5), quantity_reserved: D.new(2)},
          uuid4() => %Batch{quantity_on_hand: D.new(8), quantity_reserved: D.new(6)}
        }
      }

      assert event = StockHandler.handle(state, cmd)
      assert %StockReserved{transactions: transactions} = event
      assert D.cmp(event.quantity, cmd.quantity) == :eq
      assert event.account_id == cmd.account_id
      assert event.stockable_id == cmd.stockable_id
      assert event.movement_id == cmd.movement_id
      assert event.line_item_id == cmd.line_item_id
      assert map_size(transactions) == 2
    end
  end
end
