defmodule FCInventory.StockHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.Authorization

  alias FCInventory.Stock
  alias FCInventory.Worker
  alias FCInventory.LocationStore
  alias FCInventory.{
    ReserveStock,
    DecreaseReservedStock,
    CommitStock,

    AddEntry,
    UpdateEntry,
    CommitEntry,
    DeleteEntry
  }

  def handle(stock, %ReserveStock{} = cmd) do
    location = LocationStore.get(cmd.account_id, cmd.stock_id.location_id)
    txn =
      cmd
      |> Map.take([:serial_number, :quantity, :expected_commit_date])
      |> Map.put(:id, cmd.transaction_id)
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}

    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Stock.reserve(stock, location, txn, &1._staff_))
    |> unwrap_ok()
  end

  def handle(stock, %AddEntry{} = cmd) do
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}

    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Stock.add_entry(stock, &1, &1._staff_))
    |> unwrap_ok()
  end

  def handle(stock, %DecreaseReservedStock{} = cmd) do
    location = LocationStore.get(cmd.account_id, cmd.stock_id.location_id)
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}

    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Stock.decrease_reserved(stock, location, &1.transaction_id, &1.quantity, &1._staff_))
    |> unwrap_ok()
  end

  def handle(stock, %CommitStock{} = cmd) do
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}

    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Stock.commit(stock, &1.transaction_id, &1._staff_))
    |> unwrap_ok()
  end

  def handle(stock, %CommitEntry{} = cmd) do
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}

    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Stock.commit_entry(stock, &1.entry_id, &1._staff_))
    |> unwrap_ok()
  end

  def handle(stock, %UpdateEntry{} = cmd) do
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}
    fields = Map.take(cmd, cmd.effective_keys)

    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Stock.update_entry(stock, &1.entry_id, fields, &1._staff_))
    |> unwrap_ok()
  end

  def handle(stock, %DeleteEntry{} = cmd) do
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}

    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Stock.delete_entry(stock, &1.entry_id, &1._staff_))
    |> unwrap_ok()
  end
end
