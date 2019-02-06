defmodule FCInventory.BatchPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCInventory.{AddBatch, UpdateBatch, DeleteBatch}

  def authorize(%AddBatch{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%UpdateBatch{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%DeleteBatch{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(_, _), do: {:error, :access_denied}
end
