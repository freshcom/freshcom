defmodule FCIdentity.CommandValidator do
  alias FCIdentity.UsernameStore

  def unique_username(nil, _), do: :ok

  def unique_username(username, cmd) do
    unless UsernameStore.exist?(username, Map.get(cmd, :account_id)) do
      :ok
    else
      {:error, :taken}
    end
  end
end