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
    ReserveStock
  }
  alias FCInventory.{
    BatchAdded,
    BatchUpdated,
    BatchDeleted,
    StockReserved,
    StockPartiallyReserved,
    StockReservationFailed
  }
  alias FCInventory.{Transaction, Batch}

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

  def handle(state, %UpdateBatch{} = cmd) do
    default_locale = DefaultLocaleStore.get(state.account_id)
    translatable_fields = Batch.translatable_fields()
    batch = state.batches[cmd.batch_id]

    cmd
    |> authorize(state)
    ~>> ensure_batch_exist(batch)
    ~> merge_to(%BatchUpdated{})
    ~> put_translations(batch, translatable_fields, default_locale)
    ~> put_original_fields(batch)
    |> unwrap_ok()
  end

  def handle(state, %DeleteBatch{} = cmd) do
    batch = state.batches[cmd.batch_id]

    cmd
    |> authorize(state)
    ~>> ensure_batch_exist(batch)
    ~> merge_to(%BatchDeleted{})
    |> unwrap_ok()
  end

  defp reserve(cmd, state) do
    available_batches = Enum.into(state.batches, [])
    transactions = reserve_batches(available_batches, cmd.quantity, %{})
    quantity_reserved = Enum.reduce(transactions, D.new(0), fn {_, txn}, acc -> D.add(acc, txn.quantity) end)

    cond do
      D.cmp(quantity_reserved, D.new(0)) == :eq ->
        merge(%StockReservationFailed{}, cmd)

      D.cmp(quantity_reserved, cmd.quantity) == :lt ->
        %StockPartiallyReserved{}
        |> Map.put(:quantity_target, cmd.quantity)
        |> Map.put(:quantity_reserved, quantity_reserved)
        |> Map.put(:transactions, transactions)
        |> merge(cmd)

      D.cmp(quantity_reserved, cmd.quantity) == :eq ->
        merge(%StockReserved{transactions: transactions}, cmd)
    end
  end

  defp reserve_batches([], _, transactions) do
    transactions
  end

  defp reserve_batches([{id, batch} | batches], quantity, transactions) do
    quantity_available = D.sub(batch.quantity_on_hand, batch.quantity_reserved)

    cond do
      D.cmp(quantity, D.new(0)) == :eq ->
        transactions

      D.cmp(quantity_available, quantity) == :lt ->
        transaction = reserve_batch(id, quantity_available)
        transactions = Map.put(transactions, uuid4(), transaction)
        reserve_batches(batches, D.sub(quantity, transaction.quantity), transactions)

      true ->
        transaction = reserve_batch(id, quantity)
        Map.put(transactions, uuid4(), transaction)
    end
  end

  defp reserve_batch(batch_id, quantity) do
    %Transaction{status: "reserved", source_batch_id: batch_id, quantity: quantity}
  end

  defp ensure_batch_exist(_, nil), do: {:error, {:not_found, :batch}}
  defp ensure_batch_exist(cmd, _), do: {:ok, cmd}
end
