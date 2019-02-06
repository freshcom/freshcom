defmodule FCInventory.StoragePolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCInventory.{AddStorage, UpdateStorage}

  def authorize(%AddStorage{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%UpdateStorage{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  # def authorize(%DeleteStorage{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  def authorize(_, _), do: {:error, :access_denied}
end
