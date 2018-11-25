defmodule FCIdentity.UsernameStore do
  @doc """
  Keep the the username from the given event for future use.
  """
  @spec put(String.t(), String.t(), String.t() | nil) :: :ok | {:error, :key_already_exist}
  def put(username, user_id, account_id \\ nil) when is_binary(username) do
    key = generate_key(String.downcase(username), account_id)

    case FCStateStorage.put(key, %{user_id: user_id}, allow_overwrite: false) do
      {:ok, _} -> :ok
      {:error, :key_already_exist} -> {:error, :username_already_exist}
    end
  end

  @spec get(String.t(), String.t()) :: String.t()
  def get(username, account_id \\ nil) do
    key = generate_key(String.downcase(username), account_id)

    case FCStateStorage.get(key) do
      %{user_id: user_id} -> user_id
      _ -> nil
    end
  end

  def delete(username, account_id \\ nil) do
    key = generate_key(String.downcase(username), account_id)
    FCStateStorage.delete(key)
  end

  defp generate_key(username, nil) do
    "fc_identity/username/#{username}"
  end

  defp generate_key(username, account_id) do
    "fc_identity/username/#{account_id}/#{username}"
  end
end