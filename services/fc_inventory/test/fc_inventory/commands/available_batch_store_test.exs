defmodule FCInventory.AvailableBatchStoreTest do
  use FCInventory.UnitCase, async: true

  alias Decimal, as: D
  alias FCInventory.AvailableBatchStore

  describe "#put and #get" do
    test "given new stockable" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch_id = uuid4()

      AvailableBatchStore.put(account_id, stockable_id, batch_id, D.new(5))
      batches = %{batch_id => %{available_quantity: D.new(5)}}

      assert AvailableBatchStore.get(account_id, stockable_id) == batches
    end

    test "given existing stockable and new batch" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch1_id = uuid4()
      batch2_id = uuid4()

      AvailableBatchStore.put(account_id, stockable_id, batch1_id, D.new(5))
      AvailableBatchStore.put(account_id, stockable_id, batch2_id, D.new(10))

      batches = %{
        batch1_id => %{available_quantity: D.new(5)},
        batch2_id => %{available_quantity: D.new(10)}
      }

      assert AvailableBatchStore.get(account_id, stockable_id) == batches
    end

    test "given existing stockable and existing batch" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch_id = uuid4()

      AvailableBatchStore.put(account_id, stockable_id, batch_id, D.new(5))
      AvailableBatchStore.put(account_id, stockable_id, batch_id, D.new(10))

      batches = %{
        batch_id => %{available_quantity: D.new(10)}
      }

      assert AvailableBatchStore.get(account_id, stockable_id) == batches
    end
  end

  describe "#delete" do
    test "non existing stockable" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch_id = uuid4()

      assert AvailableBatchStore.delete(account_id, stockable_id, batch_id) == :ok
      assert AvailableBatchStore.get(account_id, stockable_id) == %{}
    end

    test "non existing batch_id" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch1_id = uuid4()
      batch2_id = uuid4()

      AvailableBatchStore.put(account_id, stockable_id, batch1_id, D.new(5))
      batches = %{batch1_id => %{available_quantity: D.new(5)}}

      assert AvailableBatchStore.delete(account_id, stockable_id, batch2_id) == :ok
      assert AvailableBatchStore.get(account_id, stockable_id) == batches
    end

    test "existing batch_id" do
      account_id = uuid4()
      stockable_id = uuid4()
      batch_id = uuid4()

      AvailableBatchStore.put(account_id, stockable_id, batch_id, D.new(5))

      assert AvailableBatchStore.delete(account_id, stockable_id, batch_id) == :ok
      assert AvailableBatchStore.get(account_id, stockable_id) == %{}
    end
  end
end
