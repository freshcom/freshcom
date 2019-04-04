defmodule FCInventory.OrderProcessingFinished do
  use FCBase, :event

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :staff_id, String.t()

    field :order_id, String.t()
    field :original_status, String.t()
    field :status, String.t()
  end
end
