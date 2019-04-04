defmodule FCInventory.OrderHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.Authorization

  alias FCInventory.{
    CreateOrder,
    MarkOrder,
    RequestStockReservation,
    RecordStockReservation,
    FinishStockReservation,
    StartOrderProcessing,
    ProcessOrderItem,
    FinishOrderProcessing
  }
  alias FCInventory.Order
  alias FCInventory.{Associate, Worker}

  def handle(%Order{id: nil}, %CreateOrder{} = cmd) do
    cmd
    |> authorize(Associate)
    |> OK.flat_map(&Order.create(&1, &1._staff_))
    |> unwrap_ok()
  end

  def handle(_, %CreateOrder{}), do: {:error, {:already_exist, :order}}
  def handle(%Order{id: nil}, _), do: {:error, {:not_found, :order}}
  def handle(%Order{status: "deleted"}, _), do: {:error, {:already_deleted, :order}}

  def handle(order, %MarkOrder{} = cmd) do
    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Order.mark(order, cmd.status, &1._staff_))
    |> unwrap_ok()
  end

  def handle(order, %RequestStockReservation{} = cmd) do
    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Order.request_stock_reservation(order, &1._staff_))
    |> unwrap_ok()
  end

  def handle(order, %RecordStockReservation{} = cmd) do
    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Order.record_stock_reservation(order, cmd.sku, cmd.serial_number, cmd.quantity, &1._staff_))
    |> unwrap_ok()
  end

  def handle(order, %FinishStockReservation{} = cmd) do
    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Order.finish_stock_reservation(order, &1._staff_))
    |> unwrap_ok()
  end

  def handle(order, %StartOrderProcessing{} = cmd) do
    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Order.start_processing(order, cmd.status, &1._staff_))
    |> unwrap_ok()
  end

  def handle(order, %ProcessOrderItem{} = cmd) do
    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Order.process_item(order, cmd.sku, cmd.serial_number, cmd.quantity, &1._staff_))
    |> unwrap_ok()
  end

  def handle(order, %FinishOrderProcessing{} = cmd) do
    cmd
    |> authorize(Worker)
    |> OK.flat_map(&Order.finish_processing(order, cmd.status, &1._staff_))
    |> unwrap_ok()
  end

  # def handle(txn, %PrepareTransaction{} = cmd) do
  #   cmd
  #   |> authorize(Worker)
  #   |> OK.flat_map(&Transaction.request_preparation(txn, &1._staff_))
  #   |> unwrap_ok()
  # end

  # def handle(txn, %CompleteTransactionPrep{} = cmd) do
  #   cmd
  #   |> authorize(Worker)
  #   |> OK.flat_map(&Transaction.complete_preparation(txn, &1.quantity, &1._staff_))
  #   |> unwrap_ok()
  # end

  # def handle(txn, %UpdateTransaction{} = cmd) do
  #   cmd
  #   |> authorize(Worker)
  #   |> OK.flat_map(&Transaction.update(txn, Map.take(&1, &1.effective_keys), &1._staff_))
  #   |> unwrap_ok()
  # end

  # def handle(txn, %MarkTransaction{} = cmd) do
  #   cmd
  #   |> authorize(System)
  #   |> OK.flat_map(&Transaction.mark(txn, &1.status, &1._staff_))
  #   |> unwrap_ok()
  # end

  # def handle(txn, %CommitTransaction{} = cmd) do
  #   cmd
  #   |> authorize(Worker)
  #   |> OK.flat_map(&Transaction.request_commit(txn, &1._staff_))
  #   |> unwrap_ok()
  # end

  # def handle(txn, %CompleteTransactionCommit{} = cmd) do
  #   cmd
  #   |> authorize(Worker)
  #   |> OK.flat_map(&Transaction.complete_commit(txn, &1._staff_))
  #   |> unwrap_ok()
  # end

  # def handle(txn, %DeleteTransaction{} = cmd) do
  #   cmd
  #   |> authorize(Worker)
  #   |> OK.flat_map(&Transaction.delete(txn, &1._staff_))
  #   |> unwrap_ok()
  # end
end
