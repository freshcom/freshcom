```
StockMovement
- status                pending/drafted/partially_reserved/reserved/partially_picked/picked/partially_packed/packed/transit/partially_completed/completed

StockLineItem
- status                pending/drafted/partially_reserved/reserved/partially_picked/picked/partially_packed/packed/transit/partially_completed/completed

StockTransaction
- transaction_id
- source_type
- source_id
- destination_type
- destination_id
- status                pending/partially_reserved/reserved/partially_picked/picked/partially_packed/packed/transit/partially_completed/completed
- quantity              12
- quantity_processed    12

PickStock
- stockable_id
- batch_id
- transaction_id
- quantity

PackStock


StockTransaction
- status                 pending/committed
- quantity               5
- source_batch           test1
- destination_batch      test2
- fulfillment_line_item

Batch
- current_quantity
- incoming_quantity
- outgoing_quantity

Fulfillment Line Item
- target_quantity
- filled_quantity

Stock Reservation
- stockable_id
- status              pending/reserved/packed/fulfilled

Stock Movement
-

CreateLineItem -> LineItemCreated
ReserveLineItem -> LineItemReserved

PackLineItem -> LineItemPacked

ChangeStockReservation -> StockReservationChanged
CompleteStockReservation -> StockReservationCompleted
```