defmodule FCInventory.Stock do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias Decimal, as: D
  alias FCInventory.{Batch, BatchReservation}
  alias FCInventory.{
    BatchAdded,
    BatchUpdated,
    BatchDeleted,
    StockReserved,
    StockPartiallyReserved,
    StockReservationFailed,
    StockReservationDecreased,
    BatchReserved,
    BatchReservationDecreased
  }

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :batches, map(), default: %{}
  end

  def apply(%{} = state, %BatchAdded{} = event) do
    batch = merge(%Batch{}, event)
    batches = Map.put(state.batches, event.batch_id, batch)

    %{
      state
      | id: event.stockable_id,
        account_id: event.account_id,
        batches: batches
    }
  end

  def apply(state, %BatchUpdated{} = event) do
    batch =
      state.batches[event.batch_id]
      |> cast(event)
      |> apply_changes()

    batches = Map.put(state.batches, event.batch_id, batch)

    %{state | batches: batches}
  end

  def apply(state, %BatchDeleted{} = event) do
    batches = Map.drop(state.batches, [event.batch_id])
    %{state | batches: batches}
  end

  def apply(%{batches: batches} = state, %BatchReserved{} = event) do
    rsv = merge(%BatchReservation{}, event)
    batch = Batch.add_reservation(batches[event.batch_id], rsv)

    put_batch(state, event.batch_id, batch)
  end

  def apply(%{batches: batches} = state, %BatchReservationDecreased{} = event) do
    batch = Batch.decrease_reservation(batches[event.batch_id], event.reservation_id, event.quantity)
    put_batch(state, event.batch_id, batch)
  end

  def apply(state, %et{}) when et in [StockReserved, StockPartiallyReserved, StockReservationFailed, StockReservationDecreased], do: state

  defp put_batch(%{batches: batches} = state, id, batch) do
    %{state | batches: Map.put(batches, id, batch)}
  end
end
