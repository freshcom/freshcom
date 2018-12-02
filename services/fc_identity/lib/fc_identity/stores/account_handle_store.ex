defmodule FCIdentity.AccountHandleStore do
  @doc """
  Keep the the alias from the given event for future use.
  """
  @spec put(String.t(), String.t()) :: :ok | {:error, :key_already_exist}
  def put(handle, account_id) when is_binary(handle) do
    key = generate_key(String.downcase(handle))

    case FCStateStorage.put(key, %{account_id: account_id}, allow_overwrite: false) do
      {:ok, _} -> :ok
      {:error, :key_already_exist} -> {:error, :alias_already_exist}
    end
  end

  @spec get(String.t()) :: String.t()
  def get(handle) do
    key = generate_key(String.downcase(handle))

    case FCStateStorage.get(key) do
      %{account_id: account_id} -> account_id
      _ -> nil
    end
  end

  def delete(handle) do
    key = generate_key(String.downcase(handle))

    FCStateStorage.delete(key)
  end

  defp generate_key(handle) do
    "fc_identity/account_handle/#{handle}"
  end
end