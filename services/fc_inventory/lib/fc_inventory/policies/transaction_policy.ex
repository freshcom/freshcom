defmodule FCInventory.TransactionPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCInventory.{
    DraftTransaction,
    PrepareTransaction,
    UpdateTransaction,
    CommitTransaction,
    DeleteTransaction
  }

  def authorize(%DraftTransaction{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%PrepareTransaction{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%UpdateTransaction{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%CommitTransaction{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%DeleteTransaction{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(_, _), do: {:error, :access_denied}
end
