defmodule FCInventory.Transaction do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  import UUID

  alias Decimal, as: D
  alias FCInventory.{
    TransactionDrafted,
    TransactionPrepared,
    TransactionUpdated,
    TransactionMarked,
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

    field :sku_id, String.t()
    field :serial_number, String.t()
    field :source_id, String.t()
    field :destination_id, String.t()

    # draft, zero_stock, action_required, ready
    field :status, String.t(), default: "draft"
    field :quantity, Decimal.t()
    field :quantity_prepared, Decimal.t(), default: Decimal.new(0)
    field :expected_completion_date, DateTime.t()

    field :number, String.t()
    field :name, String.t()
    field :description, String.t()
    field :label, String.t()
  end

  def draft(fields, staff) do
    merge_to(fields, %TransactionDrafted{transaction_id: uuid4(), staff_id: staff.id})
  end

  def request_preparation(txn, staff) do
    merge_to(txn, %TransactionPrepRequested{transaction_id: txn.id, staff_id: staff.id})
  end

  def complete_preparation(txn, completed_quantity, staff) do
    prepared = D.add(txn.quantity_prepared, completed_quantity)

    event = cond do
      D.cmp(prepared, D.new(0)) == :eq ->
        %TransactionPrepFailed{status: "zero_stock"}

      D.cmp(prepared, txn.quantity) == :eq ->
        %TransactionPrepared{status: "ready"}

      true ->
        %TransactionPrepared{status: "action_required"}
    end

    event
    |> Map.put(:staff_id, staff.id)
    |> Map.put(:transaction_id, txn.id)
    |> Map.put(:quantity, completed_quantity)
    |> merge(txn, except: [:status, :quantity])
  end

  def apply(state, %TransactionDrafted{} = event) do
    %{state | id: event.transaction_id}
    |> merge(event)
  end

  def apply(state, %TransactionPrepRequested{}) do
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

  def apply(state, %TransactionCommitRequested{}) do
    %{state | status: "committing"}
  end

  def apply(state, %TransactionCommitted{}) do
    %{state | status: "committed"}
  end

  def apply(state, %TransactionUpdated{} = event) do
    state
    |> cast(event)
    |> apply_changes()
  end

  def apply(state, %TransactionMarked{} = event) do
    %{state | status: event.status}
  end

  def apply(state, %TransactionDeleted{}) do
    %{state | status: "deleted"}
  end
end
