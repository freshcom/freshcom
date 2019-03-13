defmodule FCInventory.StockTest do
  use FCInventory.UnitCase, async: true

  alias Decimal, as: D
  alias FCInventory.{
    EntryDeleted,
    StockReserved
  }
  alias FCInventory.{Stock, Batch, Entry}

  test "apply EntryDeleted" do
    serial_number = "SN1234"
    transaction_id = uuid4()
    entry_id = uuid4()

    state = %Stock{
      batches: %{
        serial_number => %Batch{
          quantity_incoming: D.new(7),
          entries: %{
            transaction_id => %{
              entry_id => %Entry{quantity: D.new(5)},
              uuid4() => %Entry{quantity: D.new(2)}
            }
          }
        }
      }
    }

    event = %EntryDeleted{
      serial_number: serial_number,
      transaction_id: transaction_id,
      entry_id: entry_id
    }

    assert state = Stock.apply(state, event)
    assert batch = state.batches[serial_number]
    assert D.cmp(batch.quantity_incoming, D.new(2)) == :eq
    assert map_size(batch.entries[transaction_id]) == 1
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
