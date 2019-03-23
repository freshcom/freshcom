defmodule FCInventory.TransactionHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.TransactionPolicy

  alias FCInventory.{
    DraftTransaction,
    PrepareTransaction,
    UpdateTransaction,
    MarkTransaction,
    CommitTransaction,
    DeleteTransaction,
    CompleteTransactionPrep,
    CompleteTransactionCommit
  }
  alias FCInventory.{
    TransactionCommitRequested,
    TransactionCommitted,
    TransactionUpdated,
    TransactionMarked,
    TransactionDeleted
  }
  alias FCInventory.Transaction
  alias FCInventory.Worker

  def authorize(cmd, _, type) do
    case type.from(cmd._staff_) do
      nil -> {:error, {:unauthorized, :staff}}
      staff -> {:ok, %{cmd | _staff_: staff}}
    end
  end

  def handle(%Transaction{id: nil} = txn, %DraftTransaction{} = cmd) do
    cmd
    |> authorize(txn, Worker)
    |> OK.flat_map(&Transaction.draft(&1, &1._staff_))
    |> unwrap_ok()
  end

  def handle(_, %DraftTransaction{}), do: {:error, {:already_exist, :transaction}}
  def handle(%Transaction{id: nil}, _), do: {:error, {:not_found, :transaction}}
  def handle(%Transaction{status: "deleted"}, _), do: {:error, {:already_deleted, :transaction}}

  def handle(txn, %PrepareTransaction{} = cmd) do
    cmd
    |> authorize(txn, Worker)
    |> OK.flat_map(&Transaction.request_preparation(txn, &1._staff_))
    |> unwrap_ok()
  end

  def handle(txn, %CompleteTransactionPrep{} = cmd) do
    cmd
    |> authorize(txn, Worker)
    |> OK.flat_map(&Transaction.complete_preparation(txn, &1.quantity, &1._staff_))
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

  def handle(state, %MarkTransaction{} = cmd) do
    event = merge(%TransactionMarked{original_status: state.status}, state)

    cmd
    |> authorize(state)
    ~> merge_to(event)
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
    event = merge(%TransactionCommitted{}, state)

    cmd
    |> authorize(state)
    ~> merge_to(event)
    |> unwrap_ok()
  end

  def handle(%{status: "committed"}, %DeleteTransaction{}) do
    {:error, {:validation_failed, [{:error, :status, :cannot_be_committed}]}}
  end

  def handle(state, %DeleteTransaction{} = cmd) do
    event = merge(%TransactionDeleted{}, state)

    cmd
    |> authorize(state)
    ~> merge_to(event)
    |> unwrap_ok()
  end

  defp validate_update(cmd, %{status: "draft"}), do: {:ok, cmd}
  defp validate_update(cmd, %{status: "zero_stock"}), do: {:ok, cmd}

  defp validate_update(cmd, _) do
    if Enum.member?(cmd.effective_keys, :serial_number) do
      {:error, {:validation_failed, [{:error, :serial_number, :cannot_be_updated}]}}
    else
      {:ok, cmd}
    end
  end

  defp update(cmd, %{status: "draft"} = txn) do
    %TransactionUpdated{}
    |> merge(txn)
    |> merge(cmd)
  end

  defp update(%{effective_keys: ekeys} = cmd, %{status: "ready"} = txn) do
    event =
      %TransactionUpdated{}
      |> merge(txn)
      |> merge(cmd)

    if Enum.member?(ekeys, :quantity) do
      [
        event,
        %TransactionMarked{
          requester_role: "system",
          account_id: cmd.account_id,
          transaction_id: cmd.transaction_id,
          movement_id: txn.movement_id,
          original_status: "ready",
          status: "action_required"
        }
      ]
    else
      event
    end
  end
end
