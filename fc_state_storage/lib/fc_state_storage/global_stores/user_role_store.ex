defmodule FCStateStorage.GlobalStore.UserRoleStore do
  @doc """
  Keep the role for future use.
  """
  @spec put(String.t(), String.t(), String.t()) :: :ok
  def put(user_id, account_id, role) do
    key = generate_key(account_id, user_id)
    {:ok, _} = FCStateStorage.put(key, %{role: role})

    :ok
  end

  @doc """
  Get the role for a specific user of an account.
  """
  @spec get(String.t(), String.t()) :: String.t()
  def get(user_id, account_id) do
    key = generate_key(account_id, user_id)

    case FCStateStorage.get(key) do
      %{role: role} -> role
      _ -> nil
    end
  end

  defp generate_key(account_id, user_id) do
    "global_store/role/#{account_id}/#{user_id}"
  end
end