defmodule FCInventory.StockHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import UUID
  import FCInventory.StockPolicy

  alias Decimal, as: D
  alias FCStateStorage.GlobalStore.DefaultLocaleStore
  alias FCInventory.{
    AddBatch,
    UpdateBatch,
    DeleteBatch,
    ReserveStock,
    CancelReservation,
    DecreaseStockReservation
  }
  alias FCInventory.{
    BatchAdded,
    BatchUpdated,
    BatchDeleted,
    BatchReserved,
    StockReserved,
    StockPartiallyReserved,
    StockReservationFailed,
    StockReservationDecreased,
    StockReservationCancelled,
    BatchReservationDecreased,
    BatchReservationCancelled
  }
  alias FCInventory.{Batch}

  def handle(state, %AddBatch{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%BatchAdded{batch_id: uuid4()})
    |> unwrap_ok()
  end

  def handle(state, %ReserveStock{} = cmd) do
    cmd
    |> authorize(state)
    ~> reserve(state)
    |> unwrap_ok()
  end

  def handle(%{id: nil}, _), do: {:error, {:not_found, :stock}}

  def handle(state, %CancelReservation{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%StockReservationCancelled{})
    |> unwrap_ok()
  end

  def handle(state, %DecreaseStockReservation{} = cmd) do
    cmd
    |> authorize(state)
    ~> decrease_reservation(state)
    |> unwrap_ok()
  end

  def handle(state, %UpdateBatch{} = cmd) do
    default_locale = DefaultLocaleStore.get(state.account_id)
    translatable_fields = Batch.translatable_fields()
    batch = state.batches[cmd.batch_id]

    cmd
    |> authorize(state)
    ~>> ensure_batch_exist(state)
    ~> merge_to(%BatchUpdated{})
    ~> put_translations(batch, translatable_fields, default_locale)
    ~> put_original_fields(batch)
    |> unwrap_ok()
  end

  def handle(state, %DeleteBatch{} = cmd) do
    cmd
    |> authorize(state)
    ~>> ensure_batch_exist(state)
    ~> merge_to(%BatchDeleted{})
    |> unwrap_ok()
  end

  defp reserve(cmd, state) do
    available_batches =
      state
      |> available_batches()
      |> Enum.into([])

    txn_events = reserve_batches(cmd, available_batches, cmd.quantity, [])
    quantity_reserved = Enum.reduce(txn_events, D.new(0), fn event, acc -> D.add(acc, event.quantity) end)

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

    unwrap_event(txn_events ++ [event])
  end

  defp reserve_batches(_, [], _, events) do
    events
  end

  defp reserve_batches(cmd, [{id, batch} | batches], quantity, events) do
    quantity_available = D.sub(batch.quantity_on_hand, batch.quantity_reserved)

    cond do
      D.cmp(quantity, D.new(0)) == :eq ->
        events

      D.cmp(quantity_available, quantity) == :lt ->
        rsv_confirmed = reservation_confirmed(cmd, id, quantity_available)
        events = events ++ [rsv_confirmed]
        reserve_batches(cmd, batches, D.sub(quantity, quantity_available), events)

      true ->
        events ++ [reservation_confirmed(cmd, id, quantity)]
    end
  end

  defp reservation_confirmed(cmd, batch_id, quantity) do
    %BatchReserved{
      requester_role: "system",
      stockable_id: cmd.stockable_id,
      movement_id: cmd.movement_id,
      batch_id: batch_id,
      status: "reserved",
      quantity: quantity
    }
  end

  defp decrease_reservation(cmd, state) do
    reservations =
      state
      |> reservations(cmd.movement_id)
      |> Enum.into([])

    events = decrease_reservation(cmd, reservations, cmd.quantity, [])
    reservation_decreased = merge(%StockReservationDecreased{}, cmd)
    events ++ [reservation_decreased]
  end

  defp decrease_reservation(_, [], _, events) do
    events
  end

  defp decrease_reservation(cmd, [{id, rsv} | reservations], quantity, events) do
    quantity_reserved = D.sub(rsv.quantity, rsv.quantity_fulfilled)

    cond do
      D.cmp(quantity, D.new(0)) == :eq ->
        events

      D.cmp(quantity_reserved, quantity) == :lt ->
        rsv_cancelled = batch_reservation_cancelled(cmd, rsv.batch_id, id)
        events = events ++ [rsv_cancelled]
        decrease_reservation(cmd, reservations, D.sub(quantity, quantity_reserved), events)

      D.cmp(quantity_reserved, quantity) == :eq ->
        events ++ [batch_reservation_cancelled(cmd, rsv.batch_id, id)]

      true ->
        events ++ [decrease_batch_reservation(cmd, rsv.batch_id, id, quantity)]
    end
  end

  defp decrease_batch_reservation(cmd, batch_id, rsv_id, quantity) do
    %BatchReservationDecreased{
      requester_role: "system",
      stockable_id: cmd.stockable_id,
      batch_id: batch_id,
      reservation_id: rsv_id,
      quantity: quantity
    }
  end

  defp batch_reservation_cancelled(cmd, batch_id, rsv_id) do
    %BatchReservationCancelled{
      requester_role: "system",
      stockable_id: cmd.stockable_id,
      batch_id: batch_id,
      reservation_id: rsv_id
    }
  end

  defp ensure_batch_exist(%{batch_id: batch_id} = cmd, state) do
    if state.batches[batch_id] do
      {:ok, cmd}
    else
      {:error, {:not_found, :batch}}
    end
  end

  defp available_batches(%{batches: batches}) do
    Enum.reduce(batches, %{}, fn {id, batch}, a_batches ->
      if Batch.is_available(batch) do
        Map.put(a_batches, id, batch)
      else
        a_batches
      end
    end)
  end

  defp reservations(%{batches: batches}, movement_id) do
    Enum.reduce(batches, %{}, fn {_, batch}, reservations ->
      Map.merge(reservations, Batch.reservations(batch, movement_id))
    end)
  end
end
