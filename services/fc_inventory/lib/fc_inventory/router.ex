defmodule FCInventory.Router do
  @moduledoc false

  use Commanded.Commands.Router

  alias FCInventory.{
    AddStorage,
    UpdateStorage,
    DeleteStorage,
    AddBatch,
    UpdateBatch,
    DeleteBatch,
    ReserveStock,
    DecreaseStockReservation,
    CreateMovement,
    MarkMovement,
    AddLineItem,
    MarkLineItem,
    ProcessLineItem,
    UpdateLineItem
  }

  alias FCInventory.{Storage, Stock, Movement}
  alias FCInventory.{StockHandler, StorageHandler, MovementHandler}

  middleware(FCBase.CommandValidation)
  middleware(FCBase.RequesterIdentification)
  middleware(FCBase.ClientIdentification)
  middleware(FCBase.IdentifierGeneration)

  identify(Storage, by: :storage_id, prefix: "stock-storage-")
  identify(Stock, by: :stockable_id, prefix: "stock-")
  identify(Movement, by: :movement_id, prefix: "stock-movement-")

  dispatch([AddStorage, UpdateStorage, DeleteStorage], to: StorageHandler, aggregate: Storage)
  dispatch(
    [
      AddBatch,
      UpdateBatch,
      DeleteBatch,
      ReserveStock,
      DecreaseStockReservation
    ],
    to: StockHandler,
    aggregate: Stock
  )
  dispatch(
    [
      CreateMovement,
      MarkMovement,
      ProcessLineItem,
      MarkLineItem,
      AddLineItem,
      UpdateLineItem
    ],
    to: MovementHandler,
    aggregate: Movement
  )
end
