defmodule FCIdentity.AppPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCIdentity.{AddApp, UpdateApp, DeleteApp}

  def authorize(%AddApp{requester_role: role, type: "standard", client_type: "system"} = cmd, _)
      when role in @dev_roles do
    {:ok, cmd}
  end

  def authorize(%UpdateApp{client_type: "system"} = cmd, state),
    do: default(cmd, state, @dev_roles)

  def authorize(%DeleteApp{client_type: "system"} = cmd, state),
    do: default(cmd, state, @dev_roles)

  def authorize(_, _), do: {:error, :access_denied}
end
