defmodule FCInventory.Batch do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCInventory.{BatchAdded, BatchUpdated, BatchDeleted}

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :stockable_id, String.t()
    field :storage_id, String.t()

    field :status, String.t()
    field :number, String.t()
    field :label, String.t()
    field :quantity_on_hand, Decimal.t()
    field :quantity_reserved, Decimal.t(), default: Decimal.new(0)
    field :expires_at, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
    field :translations, map()
  end

  def translatable_fields do
    [
      :caption,
      :description,
      :custom_data
    ]
  end

  def apply(%{} = state, %BatchAdded{} = event) do
    %{state | id: event.batch_id}
    |> merge(event)
  end

  def apply(state, %BatchUpdated{} = event) do
    state
    |> cast(event)
    |> apply_changes()
  end

  def apply(state, %BatchDeleted{}) do
    %{state | status: "deleted"}
  end
end
