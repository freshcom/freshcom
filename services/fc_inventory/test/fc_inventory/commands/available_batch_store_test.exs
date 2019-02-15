defmodule FCInventory.AvailableBatchStoreTest do
  use FCInventory.UnitCase, async: true

  alias Decimal, as: D
  alias FCInventory.AvailableBatchStore

  describe "#put and #get" do
    test "given new stockable" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch = %{
        id: uuid4(),
        quantity_on_hand: D.new(5),
        quantity_reserved: D.new(3),
        quantity_available: D.new(2),
        expires_at: Timex.shift(Timex.now(), hours: 1)
      }

      AvailableBatchStore.put(account_id, stockable_id, batch)
      batches = [batch]

      assert AvailableBatchStore.get(account_id, stockable_id) == batches
    end

    test "given existing stockable and new batch" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch1 = %{
        id: uuid4(),
        quantity_on_hand: D.new(5),
        quantity_reserved: D.new(2),
        quantity_available: D.new(3),
        expires_at: Timex.shift(Timex.now(), hours: 2)
      }
      batch2 = %{
        id: uuid4(),
        quantity_on_hand: D.new(10),
        quantity_reserved: D.new(3),
        quantity_available: D.new(7),
        expires_at: Timex.shift(Timex.now(), hours: 24)
      }

      AvailableBatchStore.put(account_id, stockable_id, batch2)
      AvailableBatchStore.put(account_id, stockable_id, batch1)

      batches = [batch1, batch2]

      assert AvailableBatchStore.get(account_id, stockable_id) == batches
    end

    test "given existing stockable and existing batch" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch_id = uuid4()
      existing_batch = %{
        id: batch_id,
        quantity_on_hand: D.new(5),
        quantity_reserved: D.new(2),
        quantity_available: D.new(3),
        expires_at: Timex.shift(Timex.now(), hours: 2)
      }
      new_batch = %{
        id: batch_id,
        quantity_on_hand: D.new(10),
        quantity_reserved: D.new(2),
        quantity_available: D.new(8),
        expires_at: Timex.shift(Timex.now(), hours: 2)
      }

      AvailableBatchStore.put(account_id, stockable_id, existing_batch)
      AvailableBatchStore.put(account_id, stockable_id, new_batch)

      batches = [new_batch]

      assert AvailableBatchStore.get(account_id, stockable_id) == batches
    end
  end

  describe "#delete" do
    test "non existing stockable" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch_id = uuid4()

      assert AvailableBatchStore.delete(account_id, stockable_id, batch_id) == :ok
      assert AvailableBatchStore.get(account_id, stockable_id) == []
    end

    test "non existing batch_id" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch1 = %{
        id: uuid4(),
        quantity_on_hand: D.new(5),
        quantity_reserved: D.new(2),
        quantity_available: D.new(3),
        expires_at: Timex.shift(Timex.now(), hours: 2)
      }

      AvailableBatchStore.put(account_id, stockable_id, batch1)
      batches = [batch1]

      assert AvailableBatchStore.delete(account_id, stockable_id, uuid4()) == :ok
      assert AvailableBatchStore.get(account_id, stockable_id) == batches
    end

    test "existing batch_id" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch = %{
        id: uuid4(),
        quantity_on_hand: D.new(5),
        quantity_reserved: D.new(2),
        expires_at: Timex.shift(Timex.now(), hours: 2)
      }

      AvailableBatchStore.put(account_id, stockable_id, batch)

      assert AvailableBatchStore.delete(account_id, stockable_id, batch.id) == :ok
      assert AvailableBatchStore.get(account_id, stockable_id) == []
    end
  end
end
