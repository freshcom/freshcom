defmodule FCIdentity.AccountPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCIdentity.{CreateAccount, UpdateAccountInfo, CloseAccount}

  def authorize(%CreateAccount{mode: "live", requester_id: nil}, _), do: {:error, :access_denied}

  def authorize(%CreateAccount{mode: "live", requester_type: "standard", client_type: "system"} = cmd, _) do
    {:ok, cmd}
  end

  def authorize(%CloseAccount{requester_type: "standard", client_type: "system"} = cmd, _) do
    {:ok, cmd}
  end

  def authorize(%UpdateAccountInfo{requester_role: role} = cmd, %{mode: "live"})
      when role in @admin_roles do
    {:ok, cmd}
  end

  def authorize(_, _), do: {:error, :access_denied}
end
