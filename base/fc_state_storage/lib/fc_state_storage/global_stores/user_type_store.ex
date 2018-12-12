defmodule FCStateStorage.GlobalStore.UserTypeStore do
  @doc """
  Keep the user type for future use.
  """
  @spec put(String.t(), String.t()) :: :ok
  def put(user_id, type) do
    key = generate_key(user_id)
    {:ok, _} = FCStateStorage.put(key, %{type: type})

    :ok
  end

  @doc """
  Get the type for a specific user.
  """
  @spec get(String.t()) :: String.t()
  def get(user_id) do
    key = generate_key(user_id)

    case FCStateStorage.get(key) do
      %{type: type} -> type
      _ -> nil
    end
  end

  defp generate_key(user_id) do
    "global_store/user_type/#{user_id}"
  end
end