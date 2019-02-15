defmodule FCInventory.AvailableBatchStore do
  import FCSupport.Normalization

  @spec put(String.t(), String.t(), map()) :: :ok
  def put(account_id, stockable_id, batch) do
    key = generate_key(account_id, stockable_id)
    batch = Map.put(batch, :stored_at, Timex.now())

    :ok = delete(account_id, stockable_id, batch.id)
    batches = _get(account_id, stockable_id)
    FCStateStorage.put(key, batches ++ [batch])

    {:ok, batch}
  end

  @spec get(String.t(), String.t()) :: map()
  def get(account_id, stockable_id) do
    _get(account_id, stockable_id)
    |> clean()
  end

  defp _get(account_id, stockable_id) do
    key = generate_key(account_id, stockable_id)

    case FCStateStorage.get(key) do
      nil ->
        []

      batches ->
        batches
        |> deserialize()
        |> sort()
    end
  end

  defp deserialize(batches) do
    Enum.map(batches, fn(batch) ->
      batch
      |> Map.put(:quantity_available, Decimal.new(batch.quantity_available))
      |> Map.put(:expires_at, from_utc_iso8601(batch.expires_at))
      |> Map.put(:stored_at, from_utc_iso8601(batch.stored_at))
    end)
  end

  defp sort(batches) do
    Enum.sort(batches, fn(batch1, batch2) ->
      cond do
        is_nil(batch1.expires_at) && is_nil(batch2.expires_at) ->
          cmp_result = DateTime.compare(batch1.stored_at, batch2.stored_at)
          Enum.member?([:lt, :eq], cmp_result)

        is_nil(batch1.expires_at) ->
          false

        is_nil(batch2.expires_at) ->
          true

        true ->
          cmp_result = DateTime.compare(batch1.expires_at, batch2.expires_at)
          Enum.member?([:lt, :eq], cmp_result)
      end
    end)
  end

  defp clean(batches) do
    Enum.map(batches, fn(batch) -> Map.drop(batch, [:stored_at]) end)
  end

  @spec delete(String.t(), String.t(), String.t()) :: :ok
  def delete(account_id, stockable_id, batch_id) do
    key = generate_key(account_id, stockable_id)
    batches = _get(account_id, stockable_id)
    target_batch = Enum.find(batches, &(&1.id == batch_id))

    cond do
      is_nil(target_batch) ->
        :ok

      length(batches) == 1 && target_batch ->
        FCStateStorage.delete(key)

      true ->
        FCStateStorage.put(key, batches -- [target_batch])
    end

    :ok
  end

  defp generate_key(account_id, stockable_id) do
    "fc_inventory/available_batch/#{account_id}/#{stockable_id}"
  end
end
