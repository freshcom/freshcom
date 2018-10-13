defmodule FCIdentity.UsernameStore do
  @doc """
  Keep the the username from the given event for future use.
  """
  @spec put(%{
    required(:username) => String.t(),
    required(:type) => String.t(),
    optional(:account_id) => String.t()
  }) :: :ok | {:error, :key_already_exist}
  def put(event) do
    key = generate_key(event)

    case FCStateStorage.put(key, %{}, allow_overwrite: false) do
      {:ok, _} -> :ok
      {:error, :key_already_exist} -> {:error, :username_already_exist}
    end
  end

  @doc """
  Return `true` if username exist, otherwise `false`
  """
  @spec exist?(String.t()) :: boolean
  def exist?(username) do
    generate_key(%{type: "standard", username: username})
    |> do_exist?()
  end

  @spec exist?(String.t(), String.t()) :: boolean
  def exist?(username, account_id) do
    generate_key(%{type: "managed", account_id: account_id, username: username})
    |> do_exist?()
  end

  defp do_exist?(key) do
    case FCStateStorage.get(key) do
      nil -> false
      _ -> true
    end
  end

  defp generate_key(%{type: "standard", username: username}) do
    "fc_identity/username/#{username}"
  end

  defp generate_key(%{type: "managed", account_id: account_id, username: username}) do
    "fc_identity/username/#{account_id}/#{username}"
  end
end