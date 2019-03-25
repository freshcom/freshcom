defmodule FCInventory.TransactionCommit do
  @moduledoc false
  use TypedStruct

  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:e6a7ac3b-332c-4569-b3a6-c8734e2d72a7",
    router: FCInventory.Router

  alias Decimal, as: D
  alias FCInventory.StockId
  alias FCInventory.{
    CommitStock,
    CommitEntry,
    CompleteTransactionCommit
  }

  alias FCInventory.{
    TransactionCommitRequested,
    EntryCommitted,
    StockCommitted,
    TransactionCommitted
  }

  @derive Jason.Encoder
  typedstruct do
    field :destination_id, String.t()
  end

  def interested?(%TransactionCommitRequested{} = event), do: {:start!, event.transaction_id}

  def interested?(%EntryCommitted{transaction_id: tid, quantity: quantity}) do
    case D.cmp(quantity, D.new(0)) do
      :lt ->
        {:continue!, tid}

      _ ->
        false
    end
  end

  def interested?(%StockCommitted{} = event), do: {:continue!, event.transaction_id}

  def interested?(%TransactionCommitted{} = event), do: {:stop, event.transaction_id}
  def interested?(_), do: false

  def handle(_, %TransactionCommitRequested{} = event) do
    %CommitStock{
      requester_role: "system",
      account_id: event.account_id,
      stock_id: %StockId{sku_id: event.sku_id, location_id: event.source_id},
      transaction_id: event.transaction_id
    }
  end

  def handle(%{destination_id: dst_id}, %EntryCommitted{} = event) do
    %CommitEntry{
      requester_role: "system",
      account_id: event.account_id,
      stock_id: %StockId{sku_id: event.stock_id.sku_id, location_id: dst_id},
      transaction_id: event.transaction_id,
      serial_number: event.serial_number,
      entry_id: event.entry_id
    }
  end

  def handle(_, %StockCommitted{} = event) do
    %CompleteTransactionCommit{
      account_id: event.account_id,
      staff_id: "system",
      transaction_id: event.transaction_id
    }
  end

  def apply(state, %TransactionCommitRequested{} = event) do
    %{state | destination_id: event.destination_id}
  end
end
