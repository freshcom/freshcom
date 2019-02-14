defmodule FCInventory.AvailableBatchStore do
  @spec put(String.t(), String.t(), String.t(), Decimal.t()) :: :ok
  def put(account_id, stockable_id, batch_id, available_quantity) do
    batches = get(account_id, stockable_id)
    key = generate_key(account_id, stockable_id)

    batches =
      case map_size(batches) do
        0 ->
          %{batch_id => %{available_quantity: available_quantity}}

        _ ->
          batch =  Map.put(batches[batch_id] || %{}, :available_quantity, available_quantity)
          Map.put(batches, batch_id, batch)
      end

    FCStateStorage.put(key, batches)

    {:ok, batches}
  end

  @spec get(String.t(), String.t()) :: map()
  def get(account_id, stockable_id) do
    key = generate_key(account_id, stockable_id)

    case FCStateStorage.get(key) do
      nil -> %{}
      batches -> batches
    end
  end

  @spec delete(String.t(), String.t(), String.t()) :: :ok
  def delete(account_id, stockable_id, batch_id) do
    batches = get(account_id, stockable_id)

    cond do
      map_size(batches) == 1 && batches[batch_id] ->
        key = generate_key(account_id, stockable_id)
        FCStateStorage.delete(key)

      true ->
        key = generate_key(account_id, stockable_id)
        batches = Map.drop(batches, [batch_id])
        FCStateStorage.put(key, batches)
    end

    :ok
  end

  defp generate_key(account_id, stockable_id) do
    "fc_inventory/available_batch/#{account_id}/#{stockable_id}"
  end
end
