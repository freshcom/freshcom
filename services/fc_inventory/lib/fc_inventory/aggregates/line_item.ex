defmodule FCInventory.LineItem do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCInventory.{LineItemCreated}

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :line_item_id, String.t()

    field :movement_id, String.t()
    field :cause_id, String.t()
    field :cause_type, String.t()
    field :quantity, Decimal.t()
    field :quantity_processed, Decimal.t()

    field :name, String.t()
    field :status, String.t()
    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
    field :translations, map()
  end

  def translatable_fields do
    [
      :name,
      :caption,
      :description,
      :custom_data
    ]
  end

  def apply(%{} = state, %LineItemCreated{} = event) do
    %{state | id: event.line_item_id}
    |> merge(event)
  end

  # def apply(state, %LineItemUpdated{} = event) do
  #   state
  #   |> cast(event)
  #   |> apply_changes()
  # end

  # def apply(state, %LineItemDeleted{}) do
  #   %{state | status: "deleted"}
  # end
end
