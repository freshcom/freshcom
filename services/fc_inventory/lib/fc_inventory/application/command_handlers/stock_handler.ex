defmodule FCInventory.StockHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import UUID
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
    StockReserved,
    StockPartiallyReserved,
    StockReservationFailed,
    ReservedStockDecreased,
    StockCommitted,

    EntryAdded,
    EntryDeleted,
    EntryUpdated,
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

  def handle(state, %DecreaseReservedStock{} = cmd) do
    location = LocationStore.get(cmd.account_id, cmd.stock_id.location_id)

    cmd
    |> authorize(state)
    ~> decrease_reserved(location, state)
    |> unwrap_ok()
  end

  def handle(state, %CommitStock{} = cmd) do
    cmd
    |> authorize(state)
    ~> commit(state)
    |> unwrap_ok()
  end

  def handle(%{batches: batches} = state, %CommitEntry{} = cmd) do
    entry = Batch.get_entry(batches, cmd.serial_number, cmd.transaction_id, cmd.entry_id)

    cmd
    |> authorize(state)
    ~>> ensure_exist(entry, {:not_found, :stock_entry})
    ~> merge_to(%EntryCommitted{quantity: entry.quantity})
    |> unwrap_ok()
  end

  def handle(%{batches: batches} = state, %UpdateEntry{} = cmd) do
    entry = Batch.get_entry(batches, cmd.serial_number, cmd.transaction_id, cmd.entry_id)

    cmd
    |> authorize(state)
    ~>> ensure_exist(entry, {:not_found, :stock_entry})
    ~> merge_to(%EntryUpdated{})
    ~> put_original_fields(entry)
    |> unwrap_ok()
  end

  def handle(%{batches: batches} = state, %DeleteEntry{} = cmd) do
    entry = Batch.get_entry(batches, cmd.serial_number, cmd.transaction_id, cmd.entry_id)
    entry = entry || %Entry{}

    cmd
    |> authorize(state)
    ~> merge_to(%EntryDeleted{quantity: entry.quantity})
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

  defp decrease_reserved(cmd, location, %{batches: batches}) do
    entries =
      batches
      |> Batch.sort(location.output_strategy)
      |> Enum.reduce([], fn {_, batch}, acc ->
        Enum.into(batch.entries[cmd.transaction_id], []) ++ acc
      end)

    {decreased_quantity, entry_events} = decrease_reserved(cmd, entries, cmd.quantity, {D.new(0), []})
    event = merge_to(cmd, %ReservedStockDecreased{quantity: decreased_quantity}, except: [:quantity])
    entry_events ++ [event]
  end

  defp decrease_reserved(_, [], _, acc), do: acc

  defp decrease_reserved(cmd, [{id, entry} | entries], quantity, {dq, events}) do
    quantity_reserved = D.minus(entry.quantity)

    cond do
      D.cmp(quantity, D.new(0)) == :eq ->
        {dq, events}

      D.cmp(quantity_reserved, quantity) == :gt ->
        new_quantity = D.minus(D.sub(quantity_reserved, quantity))
        events = events ++ [update_entry(cmd, {id, entry}, new_quantity)]
        {D.add(dq, quantity), events}

      true ->
        entry_deleted = delete_entry(cmd, {id, entry})
        remaining_quantity = D.sub(quantity, quantity_reserved)
        events = events ++ [entry_deleted]
        acc = {D.add(dq, quantity_reserved), events}
        decrease_reserved(cmd, entries, remaining_quantity, acc)
    end
  end

  defp delete_entry(cmd, {id, entry}) do
    %EntryDeleted{
      requester_role: "system",
      account_id: cmd.account_id,
      stock_id: cmd.stock_id,
      serial_number: entry.serial_number,
      transaction_id: cmd.transaction_id,
      entry_id: id,
      quantity: entry.quantity
    }
  end

  defp update_entry(cmd, {id, entry}, new_quantity) do
    %EntryUpdated{
      requester_role: "system",
      account_id: cmd.account_id,
      stock_id: cmd.stock_id,
      serial_number: entry.serial_number,
      transaction_id: cmd.transaction_id,
      entry_id: id,
      effective_keys: [:quantity],
      quantity: new_quantity
    }
    |> put_original_fields(entry)
  end

  defp location_id(stock_id) do
    [_, location_id] = String.split(stock_id, "/")
    location_id
  end
end
