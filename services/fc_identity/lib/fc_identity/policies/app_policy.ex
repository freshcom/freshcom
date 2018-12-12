defmodule FCIdentity.AppPolicy do
  @moduledoc false

  alias FCIdentity.{AddApp}

  def authorize(%{requester_role: "sysdev"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "system"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "appdev"} = cmd, _), do: {:ok, cmd}

  def authorize(%AddApp{requester_role: role, type: "account"} = cmd, _) when role in ["owner", "administrator", "developer"] do
    {:ok, cmd}
  end

  def authorize(_, _), do: {:error, :access_denied}
end