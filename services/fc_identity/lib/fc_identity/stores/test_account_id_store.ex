defmodule FCIdentity.TestAccountIdStore do
  @doc """
  Keep the test account id for future use.
  """
  @spec put(String.t(), String.t()) :: :ok
  def put(account_id, test_account_id) do
    key = generate_key(account_id)
    {:ok, _} = FCStateStorage.put(key, %{test_account_id: test_account_id})

    :ok
  end

  @doc """
  Get the test account id for a specific account.
  """
  @spec get(String.t()) :: String.t() | nil
  def get(account_id) do
    key = generate_key(account_id)

    case FCStateStorage.get(key) do
      %{test_account_id: test_account_id} -> test_account_id
      _ -> nil
    end
  end

  defp generate_key(account_id) do
    "fc_identity/test_account_id/#{account_id}"
  end
end