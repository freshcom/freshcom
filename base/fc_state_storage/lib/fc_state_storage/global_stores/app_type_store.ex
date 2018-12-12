defmodule FCStateStorage.GlobalStore.AppTypeStore do
  @doc """
  Keep the app type for future use.
  """
  @spec put(String.t(), String.t(), String.t() | nil) :: :ok
  def put(app_id, type, account_id) do
    key = generate_key(app_id, account_id)
    {:ok, _} = FCStateStorage.put(key, %{type: type})

    :ok
  end

  @doc """
  Get the type for a specific app.
  """
  @spec get(String.t(), String.t() | nil) :: String.t()
  def get(app_id, account_id) do
    key = generate_key(app_id, account_id)

    case FCStateStorage.get(key) do
      %{type: type} -> type
      _ -> nil
    end
  end

  defp generate_key(app_id, nil) do
    "global_store/app/#{app_id}"
  end

  defp generate_key(app_id, account_id) do
    "global_store/app/#{account_id}/#{app_id}"
  end
end