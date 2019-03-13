defmodule FCInventory.SerialNumberStore do
  import FCSupport.Normalization

  @doc """
  Keep the data of serial number for future use.
  """
  @spec put(String.t(), String.t(), map()) :: :ok
  def put(account_id, serial_number, data) do
    key = generate_key(account_id, serial_number)

    {:ok, _} = FCStateStorage.put(key, data)

    :ok
  end

  @doc """
  Get data related to serial number
  """
  @spec get(String.t(), String.t()) :: String.t()
  def get(account_id, serial_number) do
    key = generate_key(account_id, serial_number)

    case FCStateStorage.get(key) do
      %{} = data -> deserialize(data)
      _ -> nil
    end
  end

  def delete(account_id, serial_number) do
    key = generate_key(account_id, serial_number)

    FCStateStorage.delete(key)
  end

  defp generate_key(account_id, serial_number) do
    "fc_inventory/#{account_id}/serial_number/#{serial_number}"
  end

  defp deserialize(data) do
    data
    |> Map.put(:remove_at, from_utc_iso8601(data[:remove_at]))
    |> Map.put(:expires_at, from_utc_iso8601(data[:expires_at]))
  end
end