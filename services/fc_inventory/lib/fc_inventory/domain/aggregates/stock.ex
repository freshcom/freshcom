defmodule FCInventory.Stock do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  import UUID

  alias Decimal, as: D
  alias FCInventory.StockId
  alias FCInventory.{Batch, Entry}
  alias FCInventory.{
    StockReserved,
    ReservedStockDecreased,
    StockPartiallyReserved,
    StockReservationFailed,
    StockCommitted,

    EntryAdded,
    EntryUpdated,
    EntryCommitted,
    EntryDeleted,
  }

  typedstruct do
    field :id, StockId.t()
    field :account_id, String.t()
    field :batches, map(), default: %{}
  end

  def unwrap_event([event]), do: event
  def unwrap_event(events), do: events

  def reserve(stock, %{type: type}, req, staff) when type in ["partner", "adjustment"] do
    entry_fields = %{
      cause_id: req.order_id,
      cause_type: "Order",
      status: "planned",
      quantity: D.minus(req.quantity),
    }

    [
      add_entry(stock, entry_fields, staff),
      %StockReserved{
        account_id: stock.account_id,
        staff_id: staff.id,
        stock_id: stock.id,
        order_id: req.order_id,
        serial_number: req.serial_number,
        quantity: req.quantity
      }
    ]
  end

  def reserve(%{batches: batches} = stock, %{output_strategy: output_strategy}, req, staff) do
    available_batches =
      batches
      |> Batch.with_serial_number(req.serial_number)
      |> Batch.available()
      |> Batch.sort(output_strategy)

    entry_events = do_reserve(stock, available_batches, req, req.quantity, staff, [])
    quantity_reserved =
      entry_events
      |> Enum.reduce(D.new(0), fn event, acc -> D.add(acc, event.quantity) end)
      |> D.minus()

    event =
      cond do
        D.cmp(quantity_reserved, D.new(0)) == :eq ->
          %StockReservationFailed{quantity: req.quantity}

        D.cmp(quantity_reserved, req.quantity) == :lt ->
          %StockPartiallyReserved{
            quantity_requested: req.quantity,
            quantity_reserved: quantity_reserved
          }

        D.cmp(quantity_reserved, req.quantity) == :eq ->
          %StockReserved{quantity: req.quantity}
      end

    event =
      event
      |> Map.put(:stock_id, stock.id)
      |> Map.put(:order_id, req.order_id)
      |> Map.put(:account_id, stock.account_id)
      |> Map.put(:serial_number, req.serial_number)

    unwrap_event(entry_events ++ [event])
  end

  defp do_reserve(_, [], _, _, _, events) do
    events
  end

  defp do_reserve(stock, [{sn, batch} | batches], req, quantity, staff, events) do
    quantity_available = Batch.quantity_available(batch)

    cond do
      D.cmp(quantity, D.new(0)) == :eq ->
        events

      D.cmp(quantity_available, quantity) == :lt ->
        entry_fields = %{
          serial_number: sn,
          cause_id: req.order_id,
          cause_type: "Order",
          status: "planned",
          quantity: D.minus(quantity_available)
        }
        entry_added = add_entry(stock, entry_fields, staff)
        events = events ++ [entry_added]
        do_reserve(stock, batches, req, D.sub(quantity, quantity_available), staff, events)

      true ->
        entry_fields = %{
          serial_number: sn,
          cause_id: req.order_id,
          cause_type: "Order",
          status: "planned",
          quantity: D.minus(quantity)
        }
        events ++ [add_entry(stock, entry_fields, staff)]
    end
  end

  def add_entry(stock, fields, staff) do
    entry_id = Map.get(fields, :entry_id) || uuid4()
    account_id = stock.account_id || Map.get(fields, :account_id)

    fields
    |> merge_to(%EntryAdded{})
    |> Map.put(:account_id, account_id)
    |> Map.put(:stock_id, stock.id)
    |> Map.put(:entry_id, entry_id)
    |> Map.put(:staff, staff.id)
  end

  def decrease_reserved(%{batches: batches} = stock, %{output_strategy: output_strategy}, order_id, quantity, staff) do
    entries =
      batches
      |> Batch.sort(output_strategy)
      |> Enum.reduce([], fn {_, batch}, acc ->
        Enum.into(batch.txn_entries[order_id], []) ++ acc
      end)

    {quantity_decreased, events} = do_decrease_reserved(stock, entries, quantity, staff, {D.new(0), []})
    event = %ReservedStockDecreased{
      account_id: stock.account_id,
      staff_id: staff.id,
      stock_id: stock.id,
      order_id: order_id,
      quantity: quantity_decreased,
    }

    events ++ [event]
  end

  defp do_decrease_reserved(_, [], _, _, acc), do: acc

  defp do_decrease_reserved(stock, [{id, entry} | entries], quantity, staff, {quantity_decreased, events}) do
    quantity_reserved = D.minus(entry.quantity)

    cond do
      D.cmp(quantity, D.new(0)) == :eq ->
        {quantity_decreased, events}

      D.cmp(quantity_reserved, quantity) == :gt ->
        entry_fields = %{
          quantity: D.minus(D.sub(quantity_reserved, quantity))
        }
        events = events ++ [do_update_entry(stock, {id, entry}, entry_fields, staff)]
        {D.add(quantity_decreased, quantity), events}

      true ->
        entry_deleted = do_delete_entry(stock, {id, entry}, staff)
        remaining_quantity = D.sub(quantity, quantity_reserved)
        events = events ++ [entry_deleted]
        acc = {D.add(quantity_decreased, quantity_reserved), events}
        do_decrease_reserved(stock, entries, remaining_quantity, staff, acc)
    end
  end

  def update_entry(stock, entry_id, fields, staff) do
    entry = get_entry(stock, entry_id)
    do_update_entry(stock, {entry_id, entry}, fields, staff)
  end

  defp do_update_entry(_, {_, nil}, _, _), do: {:error, {:not_found, :entry}}

  defp do_update_entry(stock, {id, entry}, fields, staff) do
    ekeys = Map.keys(fields)

    %EntryUpdated{
      staff_id: staff.id,
      account_id: stock.account_id,
      stock_id: stock.id,
      serial_number: entry.serial_number,
      transaction_id: entry.transaction_id,
      entry_id: id,
      effective_keys: ekeys,
      quantity: Map.get(fields, :quantity),
      expected_commit_date: Map.get(fields, :expected_commit_date)
    }
    |> put_original_fields(entry)
  end

  def delete_entry(stock, entry_id, staff) do
    entry = get_entry(stock, entry_id)
    do_delete_entry(stock, {entry_id, entry}, staff)
  end

  defp do_delete_entry(_, {_, nil}, _), do: {:error, {:not_found, :entry}}

  defp do_delete_entry(stock, {id, entry}, staff) do
    %EntryDeleted{
      staff_id: staff.id,
      account_id: stock.account_id,
      stock_id: stock.id,
      serial_number: entry.serial_number,
      transaction_id: entry.transaction_id,
      entry_id: id,
      quantity: entry.quantity
    }
  end

  def entries(%{batches: batches}) do
    Batch.entries(batches)
  end

  def entries(%{batches: batches}, transaction_id) do
    Batch.entries(batches, transaction_id)
  end

  def get_entry(stock, entry_id) do
    stock
    |> entries()
    |> Map.get(entry_id)
  end

  def commit(stock, transaction_id, staff) do
    events = Enum.map(entries(stock, transaction_id), fn {id, entry} ->
      do_commit_entry(stock, {id, entry}, staff)
    end)

    quantity = Enum.reduce(events, D.new(0), fn e, acc -> D.add(acc, e.quantity) end)
    events ++ [%StockCommitted{
      account_id: stock.account_id,
      staff_id: staff.id,
      stock_id: stock.id,
      transaction_id: transaction_id,
      quantity: quantity
    }]
  end

  def commit_entry(stock, entry_id, staff) do
    entry = get_entry(stock, entry_id)
    do_commit_entry(stock, {entry_id, entry}, staff)
  end

  def do_commit_entry(stock, {id, entry}, staff) do
    %EntryCommitted{
      account_id: stock.account_id,
      staff_id: staff.id,
      stock_id: stock.id,
      transaction_id: entry.transaction_id,
      serial_number: entry.serial_number,
      entry_id: id,
      quantity: entry.quantity,
      committed_at: Timex.now()
    }
  end

  def apply(state, %et{}) when et in [StockReserved, StockPartiallyReserved, StockReservationFailed, ReservedStockDecreased, StockCommitted], do: state

  def apply(%{batches: batches} = state, %EntryAdded{} = event) do
    entry = merge(%Entry{id: event.entry_id}, event)
    batches = Batch.add_entry(batches, event.serial_number, entry)

    %{state | batches: batches}
  end

  def apply(%{batches: batches} = state, %EntryUpdated{} = event) do
    entry =
      batches
      |> Batch.get_entry(event.serial_number, event.transaction_id, event.entry_id)
      |> cast(event)
      |> apply_changes()

    batches = Batch.put_entry(batches, event.entry_id, entry)
    %{state | batches: batches}
  end

  def apply(%{batches: batches} = state, %EntryCommitted{} = event) do
    batches = Batch.commit_entry(batches, event.serial_number, event.transaction_id, event.entry_id)
    %{state | batches: batches}
  end

  def apply(%{batches: batches} = state, %EntryDeleted{} = event) do
    batches = Batch.delete_entry(batches, event.serial_number, event.transaction_id, event.entry_id)
    %{state | batches: batches}
  end

  def id(stockable_id, location_id) do
    "#{stockable_id}/#{location_id}"
  end

  def location_id(stock_id) do
    [_, location_id] = String.split(stock_id, "/")
    location_id
  end

  def stockable_id(stock_id) do
    [stockable_id, _] = String.split(stock_id, "/")
    stockable_id
  end
end
