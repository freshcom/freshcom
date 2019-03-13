defmodule FCInventory.BatchTest do
  use FCInventory.UnitCase, async: true

  alias Decimal, as: D

  alias FCInventory.{SerialNumberStore}
  alias FCInventory.{Batch, Entry}

  describe ".add_entry" do
    test "given no existing batch, no serial number and planned entry with negative quantity" do
      entry = %Entry{
        transaction_id: uuid4(),
        quantity: D.new(-5)
      }

      batches = Batch.add_entry(%{}, nil, entry)

      assert batch = batches[nil]
      assert D.cmp(batch.quantity_reserved, D.new(5)) == :eq
      assert map_size(batch.entries) == 1
      assert map_size(batch.entries[entry.transaction_id]) == 1
    end
  end

  describe "sort/2" do
    test "when strategy is fefo" do
      account_id = uuid4()
      SerialNumberStore.put(account_id, "SN1", %{expires_at: Timex.now()})
      SerialNumberStore.put(account_id, "SN2", %{expires_at: Timex.shift(Timex.now(), days: 2)})
      SerialNumberStore.put(account_id, "SN3", %{expires_at: nil})

      batches = %{
        nil => %Batch{account_id: account_id},
        "SN3" => %Batch{account_id: account_id},
        "SN1" => %Batch{account_id: account_id},
        "SN2" => %Batch{account_id: account_id}
      }

      assert sorted = Batch.sort(batches, "fefo")
      assert [{"SN1", _}, {"SN2", _}, {nil, _}, {"SN3", _}] = sorted
    end

    test "when strategy is fifo" do
      batches = %{
        nil => %Batch{added_at: Timex.now()},
        "SN3" => %Batch{added_at: Timex.shift(Timex.now(), days: -1)},
        "SN1" => %Batch{added_at: Timex.shift(Timex.now(), days: -3)},
        "SN2" => %Batch{added_at: Timex.shift(Timex.now(), days: -2)}
      }

      assert sorted = Batch.sort(batches, "fifo")
      assert [{"SN1", _}, {"SN2", _}, {"SN3", _}, {nil, _}] = sorted
    end

    test "when strategy is lifo" do
      batches = %{
        nil => %Batch{added_at: Timex.now()},
        "SN3" => %Batch{added_at: Timex.shift(Timex.now(), days: -1)},
        "SN1" => %Batch{added_at: Timex.shift(Timex.now(), days: -3)},
        "SN2" => %Batch{added_at: Timex.shift(Timex.now(), days: -2)}
      }

      assert sorted = Batch.sort(batches, "lifo")
      assert [{nil, _}, {"SN3", _}, {"SN2", _}, {"SN1", _}] = sorted
    end
  end
end
