defmodule FCInventory.Stock do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

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
    field :id, String.t()
    field :account_id, String.t()
    field :batches, map(), default: %{}
  end

  # def reserve(stock, %{type: type}, txn) when type in [""] do

  # end

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
