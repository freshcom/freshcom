defmodule FCIdentity.TypeKeeper do
  use Commanded.Event.Handler,
    name: "a64a6d5d-fc8c-4911-9715-d5e0ecdc9a82"

  alias FCIdentity.UserAdded
  alias FCIdentity.SimpleStore

  def handle(%UserAdded{} = event, _metadata) do
    keep(event.user_id, event.type)
  end

  @doc """
  Keep the user type for future use.
  """
  @spec keep(String.t(), String.t()) :: :ok
  def keep(user_id, type) do
    key = generate_key(user_id)
    {:ok, _} = SimpleStore.put(key, %{type: type})

    :ok
  end

  @doc """
  Get the type for a specific user.
  """
  @spec get(String.t()) :: String.t()
  def get(user_id) do
    key = generate_key(user_id)

    case SimpleStore.get(key) do
      %{type: type} -> type
      _ -> nil
    end
  end

  defp generate_key(user_id) do
    "fc_identity/type/#{user_id}"
  end
end