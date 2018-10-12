defmodule FCIdentity.UserPolicy do
  use OK.Pipe

  alias FCIdentity.{
    RegisterUser,
    AddUser,
    DeleteUser,
    ChangePassword,
    ChangeUserRole
  }

  def authorize(%{requester_role: "sysdev"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "system"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "appdev"} = cmd, _), do: {:ok, cmd}

  def authorize(%AddUser{requester_role: role} = cmd, _) when role in ["owner", "administrator"],
    do: {:ok, cmd}

  def authorize(%RegisterUser{} = cmd, _),
    do: {:ok, cmd}

  # Changing user's own password
  def authorize(%ChangePassword{requester_id: rid, user_id: uid} = cmd, _) when rid == uid,
    do: {:ok, cmd}

  # Reseting password
  def authorize(%ChangePassword{requester_id: nil} = cmd, _),
    do: {:ok, cmd}

  # Managing other user's password
  def authorize(%ChangePassword{} = cmd, state),
    do: default_authorize(cmd, state, ["owner", "administrator"])

  def authorize(%DeleteUser{} = cmd, state),
    do: default_authorize(cmd, state, ["owner", "administrator"])

  def authorize(%ChangeUserRole{} = cmd, state),
    do: default_authorize(cmd, state, ["owner", "administrator"])

  def authorize(_, _), do: {:error, :access_denied}

  defp default_authorize(cmd, state, roles) do
    cmd
    |> authorize_by_account(state.account_id)
    ~>> authorize_by_role(roles)
  end

  defp authorize_by_account(%{account_id: t_aid} = cmd, aid) when t_aid == aid do
    {:ok, cmd}
  end

  defp authorize_by_account(_, _), do: {:error, :access_denied}

  defp authorize_by_role(%{requester_role: role} = cmd, roles) do
    if role in roles do
      {:ok, cmd}
    else
      {:error, :access_denied}
    end
  end

  defp authorize_by_role(_, _), do: {:error, :access_denied}
end
