defmodule FCIdentity.CommandValidator do
  alias FCIdentity.UsernameStore

  def unique_username(nil, _), do: :ok

  def unique_username(username, cmd) do
    user_id = UsernameStore.get(username, Map.get(cmd, :account_id))

    if is_nil(user_id) || user_id == cmd.user_id do
      :ok
    else
      {:error, :taken}
    end
  end
end