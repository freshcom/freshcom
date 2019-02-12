defmodule FCInventory.LineItemPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCInventory.{CreateLineItem}

  def authorize(%CreateLineItem{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  # def authorize(%UpdateLineItem{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  # def authorize(%DeleteLineItem{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  def authorize(_, _), do: {:error, :access_denied}
end
