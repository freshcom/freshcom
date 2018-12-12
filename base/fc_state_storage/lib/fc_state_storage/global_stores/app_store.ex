defmodule FCStateStorage.GlobalStore.AppStore do
  @doc """
  Keep the app type for future use.
  """
  @spec put(String.t(), String.t(), String.t() | nil) :: :ok
  def put(app_id, type, account_id) do
    key = generate_key(app_id)
    {:ok, _} = FCStateStorage.put(key, %{type: type, account_id: account_id})

    :ok
  end

  @doc """
  Get the type for a specific app.
  """
  @spec get(String.t(), String.t() | nil) :: String.t()
  def get(app_id, account_id) do
    key = generate_key(app_id)

    case FCStateStorage.get(key) do
      %{type: _, account_id: _} = app -> app
      _ -> nil
    end
  end

  defp generate_key(app_id) do
    "global_store/app/#{app_id}"
  end
end