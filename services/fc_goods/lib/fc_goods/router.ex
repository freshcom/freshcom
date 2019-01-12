defmodule FCGoods.Router do
  @moduledoc false

  use Commanded.Commands.Router

  alias FCGoods.{
    AddStockable
  }

  alias FCGoods.{Stockable}
  alias FCGoods.{StockableHandler}

  middleware(FCBase.CommandValidation)
  middleware(FCBase.RequesterIdentification)
  middleware(FCBase.ClientIdentification)
  middleware(FCBase.IdentifierGeneration)

  identify(Stockable, by: :stockable_id, prefix: "stockable-")

  dispatch([AddStockable], to: StockableHandler, aggregate: Stockable)
end
