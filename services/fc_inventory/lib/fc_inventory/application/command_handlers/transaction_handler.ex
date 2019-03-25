defmodule FCInventory.TransactionHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

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
  alias FCInventory.Transaction
  alias FCInventory.{Worker, System}

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

  def handle(txn, %UpdateTransaction{} = cmd) do
    cmd
    |> authorize(txn, Worker)
    |> OK.flat_map(&Transaction.update(txn, Map.take(&1, &1.effective_keys), &1._staff_))
    |> unwrap_ok()
  end

  def handle(txn, %MarkTransaction{} = cmd) do
    cmd
    |> authorize(txn, System)
    |> OK.flat_map(&Transaction.mark(txn, &1.status, &1._staff_))
    |> unwrap_ok()
  end

  def handle(txn, %CommitTransaction{} = cmd) do
    cmd
    |> authorize(txn, Worker)
    |> OK.flat_map(&Transaction.request_commit(txn, &1._staff_))
    |> unwrap_ok()
  end

  def handle(txn, %CompleteTransactionCommit{} = cmd) do
    cmd
    |> authorize(txn, Worker)
    |> OK.flat_map(&Transaction.complete_commit(txn, &1._staff_))
    |> unwrap_ok()
  end

  def handle(txn, %DeleteTransaction{} = cmd) do
    cmd
    |> authorize(txn, Worker)
    |> OK.flat_map(&Transaction.delete(txn, &1._staff_))
    |> unwrap_ok()
  end
end
