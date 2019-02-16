defmodule FCInventory.AvailableBatchStore do
  import FCSupport.Normalization
  alias Decimal, as: D

  @spec put(String.t(), String.t(), map()) :: :ok
  def put(account_id, stockable_id, batch) do
    if is_available(batch) do
      key = generate_key(account_id, stockable_id)
      batch = Map.put(batch, :stored_at, Timex.now())

      :ok = delete(account_id, stockable_id, batch.id)
      batches = _get(account_id, stockable_id)
      FCStateStorage.put(key, batches ++ [batch])
    end

    {:ok, batch}
  end

  defp is_available(%{quantity_on_hand: qoh, quantity_reserved: qr, expires_at: nil}), do: qoh > qr

  defp is_available(%{quantity_on_hand: qoh, quantity_reserved: qr, expires_at: expires_at}) do
    D.cmp(qoh, qr) == :gt && Timex.before?(Timex.now(), expires_at)
  end

  @spec get(String.t(), String.t()) :: map()
  def get(account_id, stockable_id) do
    _get(account_id, stockable_id)
    |> normalize()
  end

  defp _get(account_id, stockable_id) do
    key = generate_key(account_id, stockable_id)

    case FCStateStorage.get(key) do
      nil ->
        []

      batches ->
        batches
        |> deserialize()
        |> compact!(key)
        |> sort()
    end
  end

  defp deserialize(batches) do
    Enum.map(batches, fn batch ->
      batch
      |> Map.put(:quantity_on_hand, Decimal.new(batch.quantity_on_hand))
      |> Map.put(:quantity_reserved, Decimal.new(batch.quantity_reserved))
      |> Map.put(:expires_at, from_utc_iso8601(batch.expires_at))
      |> Map.put(:stored_at, from_utc_iso8601(batch.stored_at))
    end)
  end

  defp compact!(batches, key) do
    compacted = Enum.filter(batches, &is_available/1)
    FCStateStorage.put(key, batches)

    compacted
  end

  defp sort(batches) do
    Enum.sort(batches, fn batch1, batch2 ->
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

  defp normalize(batches) do
    Enum.map(batches, fn batch ->
      batch
      |> Map.drop([:stored_at])
      |> Map.put(:quantity_available, D.sub(batch.quantity_on_hand, batch.quantity_reserved))
    end)
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
