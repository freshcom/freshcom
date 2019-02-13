defmodule FCInventory.LineItemPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCInventory.{CreateLineItem, MarkLineItem}

  def authorize(%CreateLineItem{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%MarkLineItem{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  # def authorize(%UpdateLineItem{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  # def authorize(%DeleteLineItem{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  def authorize(_, _), do: {:error, :access_denied}
end
