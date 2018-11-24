defmodule FCIdentity.UsernameStore do
  @doc """
  Keep the the username from the given event for future use.
  """
  @spec put(String.t(), String.t() | nil) :: :ok | {:error, :key_already_exist}
  def put(username, account_id \\ nil) do
    key = generate_key(username, account_id)

    case FCStateStorage.put(key, %{}, allow_overwrite: false) do
      {:ok, _} -> :ok
      {:error, :key_already_exist} -> {:error, :username_already_exist}
    end
  end

  def delete(username, account_id \\ nil) do
    key = generate_key(username, account_id)
    FCStateStorage.delete(key)
  end

  @doc """
  Return `true` if username exist, otherwise `false`
  """
  @spec exist?(String.t(), String.t() | nil) :: boolean
  def exist?(username, account_id \\ nil) do
    generate_key(username, account_id)
    |> do_exist?()
  end

  defp do_exist?(key) do
    case FCStateStorage.get(key) do
      nil -> false
      _ -> true
    end
  end

  defp generate_key(username, nil) do
    "fc_identity/username/#{username}"
  end

  defp generate_key(username, account_id) do
    "fc_identity/username/#{account_id}/#{username}"
  end
end