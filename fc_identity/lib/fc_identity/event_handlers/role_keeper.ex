defmodule FCIdentity.RoleKeeper do
  use Commanded.Event.Handler,
    name: "7acce566-f170-4b36-a1da-7655f67c65f8"

  alias FCIdentity.UserAdded
  alias FCIdentity.SimpleStore

  def handle(%UserAdded{} = event, _metadata) do
    keep(event.user_id, event.account_id, event.role)
  end

  @doc """
  Keep the role for future use.
  """
  @spec keep(String.t(), String.t(), String.t()) :: :ok
  def keep(user_id, account_id, role) do
    key = generate_key(account_id, user_id)
    {:ok, _} = SimpleStore.put(key, %{role: role})

    :ok
  end

  @doc """
  Get the role for a specific user of an account.
  """
  @spec get(String.t(), String.t()) :: String.t()
  def get(user_id, account_id) do
    key = generate_key(account_id, user_id)

    case SimpleStore.get(key) do
      %{role: role} -> role
      _ -> nil
    end
  end

  defp generate_key(account_id, user_id) do
    "fc_identity/role/#{account_id}/#{user_id}"
  end
end