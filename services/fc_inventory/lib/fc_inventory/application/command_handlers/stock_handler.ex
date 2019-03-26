defmodule FCInventory.StockHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.StockPolicy

  alias Decimal, as: D
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
  alias FCInventory.{
    StockCommitted,
    EntryCommitted
  }
  alias FCInventory.{Batch, Entry}

  def authorize(cmd, _, type) do
    case type.from(cmd._staff_) do
      nil -> {:error, {:unauthorized, :staff}}
      staff -> {:ok, %{cmd | _staff_: staff}}
    end
  end

  def handle(stock, %ReserveStock{} = cmd) do
    location = LocationStore.get(cmd.account_id, cmd.stock_id.location_id)
    txn =
      cmd
      |> Map.take([:serial_number, :quantity, :expected_commit_date])
      |> Map.put(:id, cmd.transaction_id)
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}

    cmd
    |> authorize(stock, Worker)
    |> OK.flat_map(&Stock.reserve(stock, location, txn, &1._staff_))
    |> unwrap_ok()
  end

  def handle(stock, %AddEntry{} = cmd) do
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}

    cmd
    |> authorize(stock, Worker)
    |> OK.flat_map(&Stock.add_entry(stock, &1, &1._staff_))
    |> unwrap_ok()
  end

  def handle(stock, %DecreaseReservedStock{} = cmd) do
    location = LocationStore.get(cmd.account_id, cmd.stock_id.location_id)
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}

    cmd
    |> authorize(stock, Worker)
    |> OK.flat_map(&Stock.decrease_reserved(stock, location, &1.transaction_id, &1.quantity, &1._staff_))
    |> unwrap_ok()
  end

  def handle(state, %CommitStock{} = cmd) do
    cmd
    |> authorize(state)
    ~> commit(state)
    |> unwrap_ok()

    # stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}

    # cmd
    # |> authorize(stock, Worker)
    # |> OK.flat_map(&Stock.commit(stock, &1.transaction_id, &1._staff_))
    # |> unwrap_ok()
  end

  def handle(%{batches: batches} = state, %CommitEntry{} = cmd) do
    entry = Batch.get_entry(batches, cmd.serial_number, cmd.transaction_id, cmd.entry_id)

    cmd
    |> authorize(state)
    ~>> ensure_exist(entry, {:not_found, :stock_entry})
    ~> merge_to(%EntryCommitted{quantity: entry.quantity})
    |> unwrap_ok()
  end

  def handle(%{batches: batches} = stock, %UpdateEntry{} = cmd) do
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}
    fields = Map.take(cmd, cmd.effective_keys)

    cmd
    |> authorize(stock, Worker)
    |> OK.flat_map(&Stock.update_entry(stock, &1.entry_id, fields, &1._staff_))
    |> unwrap_ok()
  end

  def handle(%{batches: batches} = stock, %DeleteEntry{} = cmd) do
    stock = %{stock | id: cmd.stock_id, account_id: cmd.account_id}

    cmd
    |> authorize(stock, Worker)
    |> OK.flat_map(&Stock.delete_entry(stock, &1.entry_id, &1._staff_))
    |> unwrap_ok()
  end

  defp commit(cmd, %{batches: batches}) do
    entries = Batch.get_entries(batches, cmd.transaction_id)
    events = Enum.map(entries, fn {id, entry} ->
      %EntryCommitted{
        requester_role: "system",
        account_id: cmd.account_id,
        stock_id: cmd.stock_id,
        transaction_id: cmd.transaction_id,
        serial_number: entry.serial_number,
        entry_id: id,
        quantity: entry.quantity,
        committed_at: Timex.now()
      }
    end)
    quantity = Enum.reduce(events, D.new(0), fn e, acc -> D.add(acc, e.quantity) end)
    events ++ [%StockCommitted{
      requester_role: "system",
      account_id: cmd.account_id,
      stock_id: cmd.stock_id,
      transaction_id: cmd.transaction_id,
      quantity: quantity
    }]
  end

  defp ensure_exist(cmd, data, error) do
    if data do
      {:ok, cmd}
    else
      {:error, error}
    end
  end
end
