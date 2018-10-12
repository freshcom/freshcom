defmodule FCIdentity.UserPolicy do
  alias FCIdentity.{
    RegisterUser,
    AddUser,
    DeleteUser,
    ChangePassword
  }

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

  # Changing user's own password
  def authorize(%ChangePassword{requester_id: rid, user_id: uid} = cmd, _) when rid == uid do
    {:ok, cmd}
  end

  # Reseting password
  def authorize(%ChangePassword{requester_id: nil} = cmd, _) do
    {:ok, cmd}
  end

  # Managing other user's password
  def authorize(%ChangePassword{requester_role: role, account_id: t_aid} = cmd, %{account_id: aid})
      when role in ["owner", "administrator"] and t_aid == aid do
    {:ok, cmd}
  end

  def authorize(_, _), do: {:error, :access_denied}
end