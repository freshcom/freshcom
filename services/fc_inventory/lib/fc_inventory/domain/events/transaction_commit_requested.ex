defmodule FCInventory.TransactionCommitRequested do
  use FCBase, :event

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :staff_id, String.t()

    field :transaction_id, String.t()
    field :sku_id, String.t()
    field :source_id, String.t()
    field :destination_id, String.t()
  end
end
