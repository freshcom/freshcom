defmodule FCInventory.TransactionHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.TransactionPolicy

  alias Decimal, as: D
  alias FCInventory.{
    DraftTransaction,
    PrepareTransaction,
    UpdateTransaction,
    CommitTransaction,
    DeleteTransaction,
    CompleteTransactionPrep,
    CompleteTransactionCommit
  }
  alias FCInventory.{
    TransactionDrafted,
    TransactionPrepRequested,
    TransactionPrepared,
    TransactionPrepFailed,
    TransactionCommitRequested,
    TransactionCommitted,
    TransactionUpdated,
    TransactionDeleted
  }
  alias FCInventory.{Transaction}

  def handle(%Transaction{id: nil} = state, %DraftTransaction{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%TransactionDrafted{})
    |> unwrap_ok()
  end

  def handle(%Transaction{id: _}, %DraftTransaction{}) do
    {:error, {:already_exist, :transaction}}
  end

  def handle(%{id: nil}, _), do: {:error, {:not_found, :transaction}}
  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :transaction}}

  def handle(state, %PrepareTransaction{} = cmd) do
    event = %TransactionPrepRequested{
      stockable_id: state.stockable_id,
      source_id: state.source_id,
      destination_id: state.destination_id,
      serial_number: state.serial_number,
      quantity: state.quantity,
      quantity_prepared: state.quantity_prepared,
      expected_commit_date: state.expected_commit_date
    }

    cmd
    |> authorize(state)
    ~> merge_to(event)
    |> unwrap_ok()
  end

  def handle(state, %CompleteTransactionPrep{} = cmd) do
    cmd
    |> authorize(state)
    ~> complete_prep(state)
    |> unwrap_ok()
  end

  def handle(state, %UpdateTransaction{} = cmd) do
    default_locale = FCStateStorage.GlobalStore.DefaultLocaleStore.get(state.account_id)
    translatable_fields = FCInventory.Transaction.translatable_fields()

    cmd
    |> authorize(state)
    ~>> validate_update(state)
    ~> update(state)
    ~> put_translations(state, translatable_fields, default_locale)
    ~> put_original_fields(state)
    |> unwrap_ok()
  end

  def handle(%{status: "ready"} = state, %CommitTransaction{} = cmd) do
    event = %TransactionCommitRequested{
      stockable_id: state.stockable_id,
      source_id: state.source_id,
      destination_id: state.destination_id
    }

    cmd
    |> authorize(state)
    ~> merge_to(event)
    |> unwrap_ok()
  end

  def handle(_, %CommitTransaction{}) do
    {:error, {:validation_failed, [{:error, :status, :must_be_ready}]}}
  end

  def handle(state, %CompleteTransactionCommit{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%TransactionCommitted{})
    |> unwrap_ok()
  end

  def handle(%{status: "committed"}, %DeleteTransaction{}) do
    {:error, {:validation_failed, [{:error, :status, :cannot_be_committed}]}}
  end

  def handle(state, %DeleteTransaction{} = cmd) do
    event = merge_to(state, %TransactionDeleted{})

    cmd
    |> authorize(state)
    ~> merge_to(event)
    |> unwrap_ok()
  end

  defp validate_update(cmd, %{status: "draft"}), do: {:ok, cmd}
  defp validate_update(cmd, %{status: "zero_stock"}), do: {:ok, cmd}

  defp validate_update(cmd, state) do
    if Enum.member?(cmd.effective_keys, :serial_number) do
      {:error, {:validation_failed, [{:error, :serial_number, :cannot_be_updated}]}}
    else
      {:ok, cmd}
    end
  end

  defp update(cmd, %{status: "draft"}) do
    merge_to(cmd, %TransactionUpdated{})
  end

  defp update(%{effective_keys: ekeys} = cmd, %{status: "ready"}) do
    if Enum.member?(ekeys, :quantity) do
      [
        merge_to(cmd, %TransactionUpdated{}),
        %TransactionPrepared{
          requester_role: "system",
          account_id: cmd.account_id,
          transaction_id: cmd.transaction_id,
          status: "action_required",
          quantity: D.new(0)
        }
      ]
    else
      merge_to(cmd, %TransactionUpdated{})
    end
  end

  def complete_prep(%{quantity: quantity} = cmd, state) do
    prepared = D.add(state.quantity_prepared, quantity)

    cond do
      D.cmp(prepared, D.new(0)) == :eq ->
        merge_to(cmd, %TransactionPrepFailed{status: "zero_stock"})

      D.cmp(prepared, state.quantity) == :eq ->
        merge_to(cmd, %TransactionPrepared{status: "ready"})

      true ->
        merge_to(cmd, %TransactionPrepared{status: "action_required"})
    end
  end
 end
