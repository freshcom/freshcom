defmodule FCIdentity.AccountPolicy do
  @moduledoc false

  alias FCIdentity.{CreateAccount, UpdateAccountInfo, CloseAccount}

  def authorize(%{requester_role: "sysdev"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "system"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "appdev"} = cmd, _), do: {:ok, cmd}
  def authorize(%{client_type: "unkown"}, _), do: {:error, :access_denied}

  def authorize(%CreateAccount{mode: "live", requester_id: nil}, _), do: {:error, :access_denied}

  def authorize(%CreateAccount{mode: "live", requester_type: "standard", client_type: "system"} = cmd, _) do
    {:ok, cmd}
  end

  def authorize(%CloseAccount{requester_type: "standard", client_type: "system"} = cmd, _) do
    {:ok, cmd}
  end

  def authorize(%UpdateAccountInfo{requester_role: role} = cmd, %{mode: "live"})
      when role in ["owner", "administrator"] do
    {:ok, cmd}
  end

  def authorize(_, _), do: {:error, :access_denied}
end
