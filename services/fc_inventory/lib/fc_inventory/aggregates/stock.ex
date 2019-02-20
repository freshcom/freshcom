defmodule FCInventory.Stock do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias Decimal, as: D
  alias FCInventory.Batch
  alias FCInventory.{
    BatchAdded,
    BatchUpdated,
    BatchDeleted,
    StockReserved,
    StockPartiallyReserved,
    StockReservationFailed
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

  def apply(state, %et{} = event) when et in [StockReserved, StockPartiallyReserved] do
    batches =
      Enum.reduce(event.transactions, state.batches, fn {_, txn}, batches ->
        batch = state.batches[txn.source_batch_id]
        batch = %{
          batch
          | quantity_reserved: D.add(batch.quantity_reserved, txn.quantity),
        }

        Map.put(batches, txn.source_batch_id, batch)
      end)

    %{state | batches: batches}
  end

  def apply(state, %StockReservationFailed{}), do: state
end
