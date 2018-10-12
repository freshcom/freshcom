defmodule FCStateStorage.GlobalStore.DefaultLocaleStore do
  @doc """
  Keep the default locale of an account for future use.
  """
  @spec put(String.t(), String.t()) :: :ok
  def put(account_id, default_locale) do
    key = generate_key(account_id)
    {:ok, _} = FCStateStorage.put(key, %{default_locale: default_locale})

    :ok
  end

  @doc """
  Get the default locale for a specific account.
  """
  @spec get(String.t()) :: String.t()
  def get(account_id) do
    key = generate_key(account_id)

    case FCStateStorage.get(key) do
      %{default_locale: default_locale} -> default_locale
      _ -> nil
    end
  end

  defp generate_key(account_id) do
    "global_store/default_locale/#{account_id}"
  end
end