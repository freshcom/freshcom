defmodule FCIdentity.AccountPolicy do
  alias FCIdentity.{CreateAccount, UpdateAccountInfo}

  def authorize(%{requester_role: "sysdev"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "system"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "appdev"} = cmd, _), do: {:ok, cmd}

  def authorize(%CreateAccount{mode: "live", requester_id: nil}, _), do: {:error, :access_denied}

  def authorize(%CreateAccount{mode: "live", requester_type: "standard"} = cmd, _) do
    {:ok, cmd}
  end

  def authorize(%UpdateAccountInfo{requester_role: "administrator"} = cmd, %{mode: "live"}) do
    {:ok, cmd}
  end

  def authorize(_, _), do: {:error, :access_denied}
end