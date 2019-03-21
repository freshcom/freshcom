defmodule FCInventory.StockHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import UUID
  import FCInventory.StockPolicy

  alias Decimal, as: D
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

  def handle(state, %ReserveStock{} = cmd) do
    location = LocationStore.get(cmd.account_id, location_id(cmd.stock_id))

    cmd
    |> authorize(state)
    ~> reserve(location, state)
    |> unwrap_ok()
  end

  def handle(state, %DecreaseReservedStock{} = cmd) do
    location = LocationStore.get(cmd.account_id, location_id(cmd.stock_id))

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

  def handle(state, %AddEntry{} = cmd) do
    entry_id = cmd.entry_id || uuid4()
    cmd = %{cmd | entry_id: entry_id}

    cmd
    |> authorize(state)
    ~> merge_to(%EntryAdded{})
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

  defp reserve(cmd, %{type: type}, _) when type in ["partner", "adjustment"] do
    [
      %EntryAdded{
        requester_role: "system",
        account_id: cmd.account_id,
        stock_id: cmd.stock_id,
        transaction_id: cmd.transaction_id,
        serial_number: cmd.serial_number,
        entry_id: uuid4(),
        status: "planned",
        quantity: D.minus(cmd.quantity),
        expected_commit_date: cmd.expected_commit_date
      },
      %StockReserved{
        requester_role: "system",
        account_id: cmd.account_id,
        stock_id: cmd.stock_id,
        transaction_id: cmd.transaction_id,
        quantity: cmd.quantity
      }
    ]
  end

  defp reserve(cmd, location, %{batches: batches}) do
    available_batches =
      batches
      |> Batch.with_serial_number(cmd.serial_number)
      |> Batch.available()
      |> Batch.sort(location.output_strategy)

    entry_events = reserve_batches(cmd, available_batches, cmd.quantity, [])
    quantity_reserved =
      entry_events
      |> Enum.reduce(D.new(0), fn event, acc -> D.add(acc, event.quantity) end)
      |> D.minus()

    event =
      cond do
        D.cmp(quantity_reserved, D.new(0)) == :eq ->
          merge(%StockReservationFailed{}, cmd)

        D.cmp(quantity_reserved, cmd.quantity) == :lt ->
          %StockPartiallyReserved{}
          |> Map.put(:quantity_requested, cmd.quantity)
          |> Map.put(:quantity_reserved, quantity_reserved)
          |> merge(cmd)

        D.cmp(quantity_reserved, cmd.quantity) == :eq ->
          merge(%StockReserved{}, cmd)
      end

    unwrap_event(entry_events ++ [event])
  end

  defp reserve_batches(_, [], _, events) do
    events
  end

  defp reserve_batches(cmd, [{sn, batch} | batches], quantity, events) do
    quantity_available = Batch.quantity_available(batch)

    cond do
      D.cmp(quantity, D.new(0)) == :eq ->
        events

      D.cmp(quantity_available, quantity) == :lt ->
        entry_added = add_entry(cmd, sn, quantity_available)
        events = events ++ [entry_added]
        reserve_batches(cmd, batches, D.sub(quantity, quantity_available), events)

      true ->
        events ++ [add_entry(cmd, sn, quantity)]
    end
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

  defp add_entry(cmd, sn, quantity) do
    %EntryAdded{
      requester_role: "system",
      stock_id: cmd.stock_id,
      transaction_id: cmd.transaction_id,
      serial_number: sn,
      entry_id: uuid4(),
      status: "planned",
      quantity: D.minus(quantity),
      expected_commit_date: cmd.expected_commit_date
    }
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
