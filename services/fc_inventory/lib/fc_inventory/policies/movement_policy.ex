defmodule FCInventory.MovementPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCInventory.{
    CreateMovement,
    AddLineItem,
    MarkLineItem
  }

  def authorize(%CreateMovement{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%AddLineItem{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}


  def authorize(%MarkLineItem{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  # def authorize(%DeleteMovement{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  def authorize(_, _), do: {:error, :access_denied}
end
