defmodule FCIdentity.AppPolicy do
  @moduledoc false

  use OK.Pipe

  alias FCIdentity.{AddApp, UpdateApp, DeleteApp}

  def authorize(%{requester_role: "sysdev"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "system"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "appdev"} = cmd, _), do: {:ok, cmd}

  def authorize(%AddApp{requester_role: role, type: "standard", client_type: "system"} = cmd, _) when role in ["owner", "administrator", "developer"] do
    {:ok, cmd}
  end

  def authorize(%UpdateApp{} = cmd, state),
    do: default_authorize(cmd, state, ["owner", "administrator", "developer"])

  def authorize(%DeleteApp{} = cmd, state),
    do: default_authorize(cmd, state, ["owner", "administrator", "developer"])

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