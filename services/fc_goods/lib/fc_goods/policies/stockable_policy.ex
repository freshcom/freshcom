defmodule FCGoods.StockablePolicy do
  @moduledoc false

  use OK.Pipe

  alias FCGoods.{AddStockable}

  def authorize(%{requester_role: "sysdev"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "system"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "appdev"} = cmd, _), do: {:ok, cmd}

  def authorize(%AddStockable{requester_role: role} = cmd, _) when role in ["owner", "administrator", "developer", "goods_specialist"] do
    {:ok, cmd}
  end

  def authorize(_, _), do: {:error, :access_denied}
end