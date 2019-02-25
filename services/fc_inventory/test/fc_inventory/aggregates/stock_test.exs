defmodule FCInventory.StockTest do
  use FCInventory.UnitCase, async: true

  alias Decimal, as: D
  alias FCInventory.{
    BatchAdded,
    BatchUpdated,
    BatchDeleted,
    StockReserved
  }
  alias FCInventory.{Stock, Batch}

  test "apply AddBatch" do
    state = %Stock{}

    event = %BatchAdded{
      account_id: uuid4(),
      stockable_id: uuid4(),
      batch_id: uuid4(),
      status: "active",
      quantity_on_hand: D.new(5)
    }

    assert state = Stock.apply(state, event)
    assert map_size(state.batches) == 1
    assert batch = state.batches[event.batch_id]
    assert batch.status == event.status
    assert batch.quantity_on_hand == event.quantity_on_hand
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
    assert batch = batches[batch_id]
    assert batch.description == nil
    assert batch.quantity_on_hand == event.quantity_on_hand
    assert batch.translations == event.translations
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

    event = %StockReserved{}

    assert Stock.apply(state, event) == state
  end
end
