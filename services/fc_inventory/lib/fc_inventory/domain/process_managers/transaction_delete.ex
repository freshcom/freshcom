# defmodule FCInventory.TransactionDelete do
#   @moduledoc false
#   use TypedStruct

#   use Commanded.ProcessManagers.ProcessManager,
#     name: "process-manager:dbda65ff-f224-4e70-8312-2b5c74c80972",
#     router: FCInventory.Router

#   alias Decimal, as: D
#   alias FCInventory.StockId
#   alias FCInventory.{
#     DecreaseReservedStock,
#     DeleteEntry
#   }

#   alias FCInventory.{
#     TransactionDeleted,
#     EntryDeleted,
#     ReservedStockDecreased
#   }

#   @derive Jason.Encoder
#   typedstruct do
#     field :destination_id, String.t()
#   end

#   def interested?(%TransactionDeleted{status: "draft"}), do: false
#   def interested?(%TransactionDeleted{} = event), do: {:start!, event.transaction_id}

#   def interested?(%EntryDeleted{transaction_id: tid, quantity: quantity} = event)
#       when not is_nil(tid) and not is_nil(quantity) do
#     case D.cmp(event.quantity, D.new(0)) do
#       :lt ->
#         {:continue!, event.transaction_id}

#       _ ->
#         false
#     end
#   end

#   def interested?(%ReservedStockDecreased{} = event), do: {:stop, event.transaction_id}
#   def interested?(_), do: false

#   def handle(_, %TransactionDeleted{} = event) do
#     %DecreaseReservedStock{
#       staff_id: "system",
#       account_id: event.account_id,
#       stock_id: %StockId{sku_id: event.sku_id, location_id: event.source_id},
#       transaction_id: event.transaction_id,
#       quantity: event.quantity_prepared
#     }
#   end

#   def handle(%{destination_id: dst_id}, %EntryDeleted{} = event) do
#     %DeleteEntry{
#       staff_id: "system",
#       account_id: event.account_id,
#       stock_id: %StockId{sku_id: event.stock_id.sku_id, location_id: dst_id},
#       transaction_id: event.transaction_id,
#       serial_number: event.serial_number,
#       entry_id: event.entry_id
#     }
#   end

#   def apply(state, %TransactionDeleted{} = event) do
#     %{state | destination_id: event.destination_id}
#   end

#   def error({:error, {:continue!, :process_not_started}}, _, _) do
#     :skip
#   end
# end
