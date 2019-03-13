# defmodule FCInventory.StockHandlerTest do
#   use FCInventory.UnitCase, async: true

#   alias Decimal, as: D
#   alias FCInventory.{
#     UpdateBatch,
#     DeleteBatch,
#     ReserveStock
#   }
#   alias FCInventory.{
#     BatchAdded,
#     BatchUpdated,
#     BatchDeleted,
#     BatchReserved,
#     StockReservationFailed,
#     StockPartiallyReserved,
#     StockReserved
#   }
#   alias FCInventory.{Stock, StockHandler}

#   setup do
#     state = %Stock{id: uuid4(), account_id: uuid4()}

#     %{state: state}
#   end
# end
