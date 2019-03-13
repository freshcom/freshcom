defmodule FCInventory.Transaction do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias Decimal, as: D
  alias FCInventory.{
    TransactionDrafted,
    TransactionPrepared,
    TransactionUpdated,
    TransactionDeleted,
    TransactionPrepRequested,
    TransactionPrepFailed,
    TransactionCommitRequested,
    TransactionCommitted
  }

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :movement_id, String.t()

    field :cause_id, String.t()
    field :cause_type, String.t()
    field :stockable_id, String.t()
    field :source_id, String.t()
    field :destination_id, String.t()
    field :serial_number, String.t()

    # draft, zero_stock, action_required, ready
    field :status, String.t(), default: "draft"
    field :quantity, Decimal.t()
    field :quantity_prepared, Decimal.t(), default: Decimal.new(0)

    field :name, String.t()
    field :number, String.t()
    field :label, String.t()
    field :expected_commit_date, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map(), default: %{}
    field :translations, map(), default: %{}
  end

  def translatable_fields do
    [
      :name,
      :caption,
      :description,
      :custom_data
    ]
  end

  def apply(state, %TransactionDrafted{} = event) do
    %{state | id: event.transaction_id}
    |> merge(event)
  end

  def apply(state, %TransactionPrepRequested{} = event) do
    %{state | status: "preparing"}
  end

  def apply(state, %TransactionPrepFailed{} = event) do
    %{state | status: event.status}
  end

  def apply(state, %TransactionPrepared{} = event) do
    %{
      state
      | status: event.status,
        quantity_prepared: D.add(state.quantity_prepared, event.quantity)
    }
  end

  def apply(state, %TransactionCommitRequested{} = event) do
    %{state | status: "committing"}
  end

  def apply(state, %TransactionCommitted{} = event) do
    %{state | status: "committed"}
  end

  def apply(state, %TransactionUpdated{} = event) do
    state
    |> cast(event)
    |> apply_changes()
  end

  def apply(state, %TransactionDeleted{} = event) do
    %{state | status: "deleted"}
  end
end
