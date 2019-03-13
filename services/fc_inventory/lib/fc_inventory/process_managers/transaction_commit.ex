defmodule FCInventory.TransactionCommit do
  @moduledoc false
  use TypedStruct

  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:e6a7ac3b-332c-4569-b3a6-c8734e2d72a7",
    router: FCInventory.Router

  import FCSupport.Struct, only: [merge_to: 3]

  alias Decimal, as: D
  alias FCInventory.Stock
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

  def interested?(%TransactionCommitRequested{} = event), do: {:start, event.transaction_id}

  def interested?(%EntryCommitted{transaction_id: tid, quantity: quantity} = event) do
    case D.cmp(event.quantity, D.new(0)) do
      :lt ->
        {:continue, event.transaction_id}

      _ ->
        false
    end
  end

  def interested?(%StockCommitted{} = event), do: {:continue, event.transaction_id}
  def interested?(%TransactionCommitted{} = event), do: {:stop, event.transaction_id}
  def interested?(_), do: false

  def handle(_, %TransactionCommitRequested{} = event) do
    %CommitStock{
      requester_role: "system",
      account_id: event.account_id,
      stock_id: Stock.id(event.stockable_id, event.source_id),
      transaction_id: event.transaction_id
    }
  end

  def handle(%{destination_id: dst_id}, %EntryCommitted{} = event) do
    stockable_id = Stock.stockable_id(event.stock_id)

    %CommitEntry{
      requester_role: "system",
      account_id: event.account_id,
      stock_id: Stock.id(stockable_id, dst_id),
      transaction_id: event.transaction_id,
      serial_number: event.serial_number,
      entry_id: event.entry_id
    }
  end

  def handle(_, %StockCommitted{} = event) do
    %CompleteTransactionCommit{
      requester_role: "system",
      account_id: event.account_id,
      transaction_id: event.transaction_id
    }
  end

  def apply(state, %TransactionCommitRequested{} = event) do
    %{state | destination_id: event.destination_id}
  end
end
