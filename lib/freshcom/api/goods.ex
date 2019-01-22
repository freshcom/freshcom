defmodule Freshcom.Goods do
  use Freshcom, :api_module

  import Freshcom.GoodsPolicy

  alias FCGoods.{AddStockable}
  alias FCGoods.{StockableAdded}
  alias Freshcom.{StockableProjector}
  alias Freshcom.{Stockable}

  @spec add_stockable(Request.t()) :: APIModule.resp()
  def add_stockable(%Request{} = req) do
    req
    |> to_command(%AddStockable{})
    |> dispatch_and_wait(StockableAdded)
    ~> Map.get(:stockable)
    ~> preload(req)
    |> to_response()
  end

  def list_stockable(%Request{} = req) do
    req = expand(req)

    req
    |> Map.put(:_filterable_keys_, [
      "number",
      "barcode",
      "label",
      "variable_weight",
      "weight",
      "weight_unit",
      "storage_type",
      "storage_size",
      "stackable",
      "width",
      "length",
      "height",
      "dimension_unit"
    ])
    |> Map.put(:_searchable_keys_, ["name", "number", "barcode", "print_name", "label"])
    |> Map.put(:_sortable_keys_, ["status", "number", "barcode", "label"])
    |> authorize(:list_stockable)
    ~> to_query(Stockable)
    ~> Repo.all()
    ~> preload(req)
    ~> translate(req.locale, req._default_locale_)
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
