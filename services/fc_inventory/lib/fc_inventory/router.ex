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
    CreateTransaction,
    UpdateTransaction,
    DeleteTransaction
  }

  alias FCInventory.{Storage, Batch, Transaction}
  alias FCInventory.{StorageHandler, BatchHandler, TransactionHandler}

  middleware(FCBase.CommandValidation)
  middleware(FCBase.RequesterIdentification)
  middleware(FCBase.ClientIdentification)
  middleware(FCBase.IdentifierGeneration)

  identify(Storage, by: :storage_id, prefix: "storage-")
  identify(Batch, by: :batch_id, prefix: "batch-")

  dispatch([AddStorage, UpdateStorage, DeleteStorage], to: StorageHandler, aggregate: Storage)
  dispatch([AddBatch, UpdateBatch, DeleteBatch], to: BatchHandler, aggregate: Batch)
  dispatch([CreateTransaction], to: TransactionHandler, aggregate: Transaction)
end
