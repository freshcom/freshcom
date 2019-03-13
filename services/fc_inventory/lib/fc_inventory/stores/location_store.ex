defmodule FCInventory.LocationStore do
  @doc """
  Keep the location for future use.
  """
  @spec put(String.t(), String.t(), map()) :: :ok
  def put(account_id, location_id, location) do
    key = generate_key(account_id, location_id)

    {:ok, _} = FCStateStorage.put(key, location)

    :ok
  end

  @doc """
  Get a location
  """
  @spec get(String.t(), String.t()) :: String.t()
  def get(account_id, location_id) do
    key = generate_key(account_id, location_id)

    case FCStateStorage.get(key) do
      %{type: _} = location -> location
      _ -> nil
    end
  end

  def delete(account_id, location_id) do
    key = generate_key(account_id, location_id)

    FCStateStorage.delete(key)
  end

  defp generate_key(account_id, location_id) do
    "fc_inventory/#{account_id}/location/#{location_id}"
  end
end