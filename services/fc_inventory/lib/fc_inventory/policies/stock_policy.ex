defmodule FCInventory.StockPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCInventory.{
    ReserveStock,
    CommitStock,
    AddEntry
  }

  def authorize(%ReserveStock{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%CommitStock{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%AddEntry{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  # def authorize(%UpdateBatch{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  # def authorize(%DeleteBatch{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  def authorize(_, _), do: {:error, :access_denied}
end
