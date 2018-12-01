defmodule FCIdentity.AccountAliasStore do
  @doc """
  Keep the the alias from the given event for future use.
  """
  @spec put(String.t(), String.t()) :: :ok | {:error, :key_already_exist}
  def put(alius, account_id) when is_binary(alius) do
    key = generate_key(String.downcase(alius))

    case FCStateStorage.put(key, %{account_id: account_id}, allow_overwrite: false) do
      {:ok, _} -> :ok
      {:error, :key_already_exist} -> {:error, :alias_already_exist}
    end
  end

  @spec get(String.t()) :: String.t()
  def get(alius) do
    key = generate_key(String.downcase(alius))

    case FCStateStorage.get(key) do
      %{account_id: account_id} -> account_id
      _ -> nil
    end
  end

  def delete(alius) do
    key = generate_key(String.downcase(alius))

    FCStateStorage.delete(key)
  end

  defp generate_key(alius) do
    "fc_identity/account_alias/#{alius}"
  end
end