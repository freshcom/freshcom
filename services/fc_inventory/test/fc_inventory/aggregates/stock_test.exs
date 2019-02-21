defmodule FCInventory.StockTest do
  use FCInventory.UnitCase, async: true

  alias Decimal, as: D
  alias FCInventory.{
    BatchAdded,
    BatchUpdated,
    BatchDeleted,
    StockReserved
  }
  alias FCInventory.{Stock, Batch, Transaction}

  test "apply AddBatch" do
    state = %Stock{}

    event = %BatchAdded{
      account_id: uuid4(),
      stockable_id: uuid4(),
      batch_id: uuid4(),
      quantity_on_hand: D.new(5)
    }

    assert state = Stock.apply(state, event)
    assert map_size(state.batches) == 1
    assert state.batches[event.batch_id]
    assert state.id == event.stockable_id
    assert state.account_id == event.account_id
  end

  test "apply BatchUpdated" do
    batch_id = uuid4()
    state = %Stock{
      batches: %{batch_id => %Batch{}}
    }

    event = %BatchUpdated{
      batch_id: batch_id,
      effective_keys: [:quantity_on_hand, :translations],
      quantity_on_hand: D.new(5),
      description: "This should not be updated to state",
      translations: %{"en" => %{"description" => "Good"}}
    }

    assert %{batches: batches} = Stock.apply(state, event)
    assert batches[batch_id].description == nil
    assert batches[batch_id].quantity_on_hand == event.quantity_on_hand
    assert batches[batch_id].translations == event.translations
  end

  test "apply BatchDeleted" do
    batch_id = uuid4()
    state = %Stock{
      batches: %{batch_id => %Batch{}}
    }

    event = %BatchDeleted{
      batch_id: batch_id
    }

    assert %{batches: batches} = Stock.apply(state, event)
    assert map_size(batches) == 0
  end

  test "apply StockReserved" do
    batch1_id = uuid4()
    batch2_id = uuid4()
    state = %Stock{
      batches: %{
        batch1_id => %Batch{},
        batch2_id => %Batch{quantity_reserved: D.new(1)}
      }
    }

    event = %StockReserved{
      transactions: %{
        uuid4() => %Transaction{source_batch_id: batch1_id, quantity: D.new(3)},
        uuid4() => %Transaction{source_batch_id: batch2_id, quantity: D.new(2)}
      }
    }

    assert %{batches: batches} = Stock.apply(state, event)
    assert D.cmp(batches[batch1_id].quantity_reserved, D.new(3)) == :eq
    assert D.cmp(batches[batch2_id].quantity_reserved, D.new(3)) == :eq
  end
end
