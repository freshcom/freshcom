defmodule Freshcom.Goods do
  import Freshcom.APIModule

  use OK.Pipe

  alias Freshcom.{APIModule, Request}
  alias FCGoods.{AddStockable}
  alias FCGoods.{StockableAdded}
  alias Freshcom.{Repo, Projector}
  alias Freshcom.{StockableProjector}

  @spec add_stockable(Request.t()) :: APIModule.resp()
  def add_stockable(%Request{} = req) do
    req
    |> to_command(%AddStockable{})
    |> dispatch_and_wait(StockableAdded)
    ~> Map.get(:stockable)
    ~> preload(req)
    |> to_response()
  end

  defp dispatch_and_wait(cmd, event) do
    dispatch_and_wait(cmd, event, &wait/1)
  end

  defp wait(%et{stockable_id: stockable_id}) when et in [StockableAdded] do
    Projector.wait([
      {:stockable, StockableProjector, &(&1.id == stockable_id)}
    ])
  end
end