defmodule FCIdentity.DefaultLocaleKeeper do
  use Commanded.Event.Handler,
    name: "e04b7e24-a659-43d2-a84f-0b9c351c23a3"

  alias FCIdentity.AccountCreated
  alias FCIdentity.SimpleStore

  def handle(%AccountCreated{} = event, _metadata) do
    keep(event.account_id, event.default_locale)
  end

  @doc """
  Keep the default locale of an account for future use.
  """
  @spec keep(String.t(), String.t()) :: :ok
  def keep(account_id, default_locale) do
    key = generate_key(account_id)
    {:ok, _} = SimpleStore.put(key, %{default_locale: default_locale})

    :ok
  end

  @doc """
  Get the default locale for a specific account.
  """
  @spec get(String.t()) :: String.t()
  def get(account_id) do
    key = generate_key(account_id)

    case SimpleStore.get(key) do
      %{default_locale: default_locale} -> default_locale
      _ -> nil
    end
  end

  defp generate_key(account_id) do
    "fc_identity/default_locale/#{account_id}"
  end
end