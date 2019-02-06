defmodule FCInventory.Router do
  @moduledoc false

  use Commanded.Commands.Router

  alias FCInventory.{
    AddStorage,
    UpdateStorage
  }

  alias FCInventory.{Storage}
  alias FCInventory.{StorageHandler}

  middleware(FCBase.CommandValidation)
  middleware(FCBase.RequesterIdentification)
  middleware(FCBase.ClientIdentification)
  middleware(FCBase.IdentifierGeneration)

  identify(Storage, by: :storage_id, prefix: "storage-")

  dispatch([AddStorage, UpdateStorage], to: StorageHandler, aggregate: Storage)
end
