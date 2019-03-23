Inventory Bounded Context

## Roles

Manager - Responsible for all inventory related matters
Associate - Responsible for providing support to sales and distribution team usually the person that interact with other departments
Worker - Responsbile for receiving and shipping and moving stocks between internal locoations
Driver -

## Use Case

- An account can be used to manage multiple warehouses
- A location is a specific place within a warehouse
- A SKU represent a specific item in a specific unit of measure
- A stock represent all quantities of a SKU at a specific location
- A serial number can be assign to a batch of items to represent that they have the same manufature's information
- Order can have many line items and each line item indicates the SKU and quantity. No pricing information will be included on the order as this is a inventory order not a sales order.
- A transaction represent a movement of a specific SKU between two locations
- A movement represent a group of transactions between the two locations
- When the quantity of a stock is decreased or increased a stock entry must be created to indicate the cause

- An associate can place orders to be shipped to customer
- An associate can place orders to be shipped to another warehouse
- An associate can help a worker do their work, but worker cannot help associate as talking to customer and other departments requires special trainning
- An associate can submit a movement request to request items be moved between locations
- An associate can reserve the item in the movement request for the worker

- A worker can set the beginning quantity of a stock
- A worker can adjust the quantity of a stock by
- A worker can mark an order as been shipped
- A worker can reserve items for an order
- A worker can reserve specific line items of an order
- A worker can create a backorder of an order
- A worker can create a movement to reserve items to be moved
- A worker can move items between locations
- A worker can receive shipments and
