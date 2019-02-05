defmodule Freshcom.Goods do
  use Freshcom, :api_module

  import FCSupport.Normalization, only: [atomize_keys: 2]
  import Freshcom.GoodsPolicy

  alias FCGoods.{AddStockable, UpdateStockable, DeleteStockable}
  alias FCGoods.{StockableAdded, StockableUpdated, StockableDeleted}
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

  @spec list_stockable(Request.t()) :: APIModule.resp()
  def list_stockable(%Request{} = req) do
    req = expand(req)

    req
    |> Map.put(:_filterable_keys_, [
      "status",
      "label",
      "variable_weight",
      "storage_type",
      "updated_at"
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

  def count_stockable(%Request{} = req) do
    req
    |> expand()
    |> Map.put(:_filterable_keys_, [
      "status",
      "label",
      "variable_weight",
      "storage_type",
      "updated_at"
    ])
    |> Map.put(:_searchable_keys_, ["name", "number", "barcode", "print_name", "label"])
    |> Map.put(:pagination, nil)
    |> authorize(:list_stockable)
    ~> to_query(Stockable)
    ~> Repo.aggregate(:count, :id)
    |> to_response()
  end

  @spec get_stockable(Request.t()) :: APIModule.resp()
  def get_stockable(%Request{} = req) do
    req
    |> expand()
    |> authorize(:get_stockable)
    ~> to_query(Stockable)
    ~> Repo.all()
    ~>> ensure_one()
    |> to_response()
  end

  @spec update_stockable(Request.t()) :: APIModule.resp()
  def update_stockable(%Request{} = req) do
    identifier = atomize_keys(req.identifier, ["id"])
    req = expand(req, only: :_default_locale_)

    req
    |> to_command(%UpdateStockable{})
    |> Map.put(:stockable_id, identifier[:id])
    |> dispatch_and_wait(StockableUpdated)
    ~> Map.get(:stockable)
    ~> preload(req)
    ~> translate(req.locale, req._default_locale_)
    |> to_response()
  end

  def delete_stockable(%Request{} = req) do
    identifier = atomize_keys(req.identifier, ["id"])

    req
    |> to_command(%DeleteStockable{})
    |> Map.put(:stockable_id, identifier[:id])
    |> dispatch_and_wait(StockableDeleted)
    ~> Map.get(:stockable)
    |> to_response()
  end

  defp dispatch_and_wait(cmd, event) do
    dispatch_and_wait(cmd, event, &wait/1)
  end

  defp wait(%et{stockable_id: stockable_id}) when et in [StockableAdded, StockableUpdated, StockableDeleted] do
    Projector.wait([
      {:stockable, StockableProjector, &(&1.id == stockable_id)}
    ])
  end
end
