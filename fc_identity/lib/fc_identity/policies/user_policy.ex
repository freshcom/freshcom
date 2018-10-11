defmodule FCIdentity.UserPolicy do
  alias FCIdentity.{RegisterUser, AddUser, DeleteUser}

  def authorize(%{requester_role: "sysdev"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "system"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "appdev"} = cmd, _), do: {:ok, cmd}

  def authorize(%AddUser{requester_role: role} = cmd, _) when role in ["owner", "administrator"] do
    {:ok, cmd}
  end

  def authorize(%RegisterUser{} = cmd, _) do
    {:ok, cmd}
  end

  def authorize(%DeleteUser{requester_role: role} = cmd, _) when role in ["owner", "administrator"] do
    {:ok, cmd}
  end

  def authorize(_, _), do: {:error, :access_denied}
end