defmodule FCIdentity.UsernameKeeper do
  use Commanded.Event.Handler,
    name: "750e4669-c458-472a-a9a3-6b00d27ec14f"

  alias FCIdentity.UserAdded
  alias FCIdentity.SimpleStore

  def handle(%UserAdded{} = event, _metadata), do: keep(event)

  @doc """
  Keep the the username from the given event for future use.
  """
  @spec keep(%{
    required(:username) => String.t(),
    required(:type) => String.t(),
    optional(:account_id) => String.t()
  }) :: :ok | {:error, :key_already_exist}
  def keep(event) do
    key = generate_key(event)

    case SimpleStore.put(key, %{}, allow_overwrite: false) do
      {:ok, _} -> :ok
      {:error, :key_already_exist} -> {:error, :username_already_exist}
    end
  end

  @doc """
  Return `true` if username exist, otherwise `false`
  """
  @spec exist?(String.t()) :: boolean
  def exist?(username) do
    generate_key(%{type: "standard", username: username})
    |> do_exist?()
  end

  @spec exist?(String.t(), String.t()) :: boolean
  def exist?(username, account_id) do
    generate_key(%{type: "managed", account_id: account_id, username: username})
    |> do_exist?()
  end

  defp do_exist?(key) do
    case SimpleStore.get(key) do
      nil -> false
      _ -> true
    end
  end

  defp generate_key(%{type: "standard", username: username}) do
    "fc_identity/username/#{username}"
  end

  defp generate_key(%{type: "managed", account_id: account_id, username: username}) do
    "fc_identity/username/#{account_id}/#{username}"
  end
end