defmodule FCInventory.TransactionPrep do
  @moduledoc false
  use TypedStruct

  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:93d9d4b3-35ae-413e-8bc8-6b35c4121b0a",
    router: FCInventory.Router

  import FCSupport.Struct, only: [merge_to: 3]

  alias Decimal, as: D
  alias FCInventory.{Stock, StockId}
  alias FCInventory.{
    ReserveStock,
    DecreaseReservedStock,
    AddEntry,
    UpdateEntry,
    DeleteEntry,
    CompleteTransactionPrep
  }

  alias FCInventory.{
    TransactionPrepRequested,
    EntryAdded,
    EntryUpdated,
    EntryDeleted,
    StockReserved,
    StockPartiallyReserved,
    StockReservationFailed,
    TransactionPrepared,
    TransactionMarked,
    TransactionPrepFailed,
    ReservedStockDecreased
  }

  @derive Jason.Encoder
  typedstruct do
    field :destination_id, String.t()
  end

  def interested?(%TransactionPrepRequested{} = event) do
    case D.cmp(event.quantity, event.quantity_prepared) do
      :eq ->
        false

      _ ->
        {:start!, event.transaction_id}
    end
  end

  def interested?(%et{transaction_id: tid, quantity: quantity} = event)
      when not is_nil(tid) and not is_nil(quantity) and et in [EntryAdded, EntryUpdated, EntryDeleted] do
    case D.cmp(event.quantity, D.new(0)) do
      :lt ->
        {:continue!, event.transaction_id}

      _ ->
        false
    end
  end

  def interested?(%StockReserved{} = event), do: {:continue!, event.transaction_id}
  def interested?(%StockPartiallyReserved{} = event), do: {:continue!, event.transaction_id}
  def interested?(%StockReservationFailed{} = event), do: {:continue!, event.transaction_id}
  def interested?(%ReservedStockDecreased{} = event), do: {:continue!, event.transaction_id}

  def interested?(%TransactionPrepared{} = event), do: {:stop, event.transaction_id}
  def interested?(%TransactionMarked{} = event), do: {:stop, event.transaction_id}
  def interested?(%TransactionPrepFailed{} = event), do: {:stop, event.transaction_id}

  def interested?(_), do: false

  def handle(_, %TransactionPrepRequested{} = event) do
    case D.cmp(event.quantity_prepared, event.quantity) do
      :lt ->
        %ReserveStock{
          requester_role: "system",
          account_id: event.account_id,
          transaction_id: event.transaction_id,
          stock_id: %StockId{sku_id: event.sku_id, location_id: event.source_id},
          serial_number: event.serial_number,
          quantity: D.sub(event.quantity, event.quantity_prepared),
          expected_commit_date: event.expected_completion_date
        }

      :gt ->
        %DecreaseReservedStock{
          requester_role: "system",
          account_id: event.account_id,
          stock_id: %StockId{sku_id: event.sku_id, location_id: event.source_id},
          transaction_id: event.transaction_id,
          quantity: D.sub(event.quantity_prepared, event.quantity)
        }
    end
  end

  def handle(%{destination_id: dst_id}, %EntryAdded{} = event) do
    %AddEntry{
      requester_role: "system",
      account_id: event.account_id,
      stock_id: %StockId{sku_id: event.stock_id.sku_id, location_id: dst_id},
      transaction_id: event.transaction_id,
      serial_number: event.serial_number,
      entry_id: event.entry_id,
      quantity: D.minus(event.quantity),
      expected_commit_date: event.expected_commit_date
    }
  end

  def handle(%{destination_id: dst_id}, %EntryUpdated{} = event) do
    update_entry =
      merge_to(event, %UpdateEntry{
          requester_role: "system",
          stock_id: %StockId{sku_id: event.stock_id.sku_id, location_id: dst_id}
        },
        except: [:requester_role, :stock_id]
      )

    if update_entry.quantity do
      %{update_entry | quantity: D.minus(update_entry.quantity)}
    else
      update_entry
    end
  end

  def handle(%{destination_id: dst_id}, %EntryDeleted{} = event) do
    %DeleteEntry{
      requester_role: "system",
      account_id: event.account_id,
      stock_id: %StockId{sku_id: event.stock_id.sku_id, location_id: dst_id},
      transaction_id: event.transaction_id,
      serial_number: event.serial_number,
      entry_id: event.entry_id
    }
  end

  def handle(_, %StockReserved{} = event) do
    %CompleteTransactionPrep{
      account_id: event.account_id,
      staff_id: "system",
      transaction_id: event.transaction_id,
      quantity: event.quantity
    }
  end

  def handle(_, %StockPartiallyReserved{} = event) do
    %CompleteTransactionPrep{
      account_id: event.account_id,
      staff_id: "system",
      transaction_id: event.transaction_id,
      quantity: event.quantity_reserved
    }
  end

  def handle(_, %StockReservationFailed{} = event) do
    %CompleteTransactionPrep{
      account_id: event.account_id,
      staff_id: "system",
      transaction_id: event.transaction_id,
      quantity: D.new(0)
    }
  end

  def handle(_, %ReservedStockDecreased{} = event) do
    %CompleteTransactionPrep{
      account_id: event.account_id,
      staff_id: "system",
      transaction_id: event.transaction_id,
      quantity: D.minus(event.quantity)
    }
  end

  def apply(state, %TransactionPrepRequested{} = event) do
    %{state | destination_id: event.destination_id}
  end

  def error({:error, {:continue!, :process_not_started}}, _, _) do
    :skip
  end
end
