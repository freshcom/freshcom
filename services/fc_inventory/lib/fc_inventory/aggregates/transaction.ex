defmodule FCInventory.Transaction do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCInventory.{TransactionCreated}

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :transaction_id, String.t()

    field :source_stockable_id, String.t()
    field :source_id, String.t()
    field :source_type, String.t()
    field :destination_stockable_id, String.t()
    field :destination_id, String.t()
    field :destination_type, String.t()

    field :status, String.t()
    field :number, String.t()
    field :quantity, Decimal.t()
    field :quantity_processed, Decimal.t()
    field :expected_completion_date, DateTime.t()

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

  def apply(%{} = state, %TransactionCreated{} = event) do
    %{state | id: event.transaction_id}
    |> merge(event)
  end

  # def apply(state, %TransactionUpdated{} = event) do
  #   state
  #   |> cast(event)
  #   |> apply_changes()
  # end

  # def apply(state, %TransactionDeleted{}) do
  #   %{state | status: "deleted"}
  # end
end
