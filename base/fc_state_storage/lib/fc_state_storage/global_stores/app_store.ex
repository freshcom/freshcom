defmodule FCStateStorage.GlobalStore.AppStore do
  @doc """
  Keep the app type for future use.
  """
  @spec put(String.t(), String.t(), String.t() | nil) :: :ok
  def put(app_id, type, account_id \\ nil) do
    key = generate_key(app_id)
    data = if account_id do
      %{type: type, account_id: account_id}
    else
      %{type: type}
    end

    {:ok, _} = FCStateStorage.put(key, data)

    :ok
  end

  @doc """
  Get the type for a specific app.
  """
  @spec get(String.t()) :: String.t()
  def get(app_id) do
    key = generate_key(app_id)

    case FCStateStorage.get(key) do
      %{type: _} = app -> app
      _ -> nil
    end
  end

  defp generate_key(app_id) do
    "global_store/app/#{app_id}"
  end
end