defmodule FCGoods.StockablePolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCGoods.{AddStockable, UpdateStockable, DeleteStockable}

  def authorize(%AddStockable{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%UpdateStockable{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(%DeleteStockable{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(_, _), do: {:error, :access_denied}
end
