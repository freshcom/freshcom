Inventory Bounded Context

## Roles

Manager - Responsible for all inventory related matters
Associate - Responsible for providing support to sales and distribution team usually the person that interact with other departments
Worker - Responsbile for receiving and shipping and moving stocks between internal locoations
Driver -

## Use Case

- An account can be used to manage multiple warehouses

- A SKU represent a specific item in a specific unit of measure
- A serial number can be assign to a batch of items to represent that they have the same manufature's information
- A unique bardcode can be assign to a SKU with a specific serial number

- A location is a specific area within a warehouse
- A storage location is an area designated for storage of stock
- A shipping location is an area designated for ready-to-ship packages
- A receiving location is an area designated for receiving shipments
- A work location is an area designated for worker to perform specific tasks on SKUs
- A location can store SKUs by bins, tote or packages
- Only 1 specific SKU can be stored in 1 bin
- Multiple SKUs can be stored in a package or tote
- Usually storage locatin store SKUs by bins
- Usually shipping and reciving location store SKUs by packages
- Usually work location store SKUs by tote

- A tote is a physical container that a worker use to move items around
- A tote can have many line items to indicate whats currently in it

- A package is a physical container that have some shipping information
- A package can have many line items to indicate whats in it

- A stock represent all quantities of a SKU at a specific location
- When the quantity of a stock is changed, an entry must be created to record the change and its cause

- A process represent a series of steps that a group of SKUs must go through to accomplish a certain task
- Each step of a process have an action and the location that the action need to be performed at
- A shipping process is a process that ends with a step at a shipping location
- A receiving process is a process that ends with a step at a storage location
- Process cannot be modified once its published, however new processes can be created
- A process cannot be removed if there is still an associated un-completed movement

- A line item represents a SKU with a specific quantity

- An order represent a group of SKUs that needs to be shipped to a customer or another warehouse
- An order can have many line items
- An order is completed when all of its line items are packaged and moved to the shipping location
- An order can use a specific shipping process, in which case a worker must follow that process to make SKUs in that order ready to ship

- A shipment represent a group of incoming SKUs
- A shipment can have many line items to indicate whats in it
- A shipment can have many packages
- A shipment is received when all of its SKUs have been put away in a storage location
- A shipment can use a specific receiving process, in which case a worker must follow that process to putaway items in that shipment

- A movement represent a group of SKUs being moved between two locations
- A movement can have many line items
- A movement may be part of a process
- A movement may be associated to an order or a shpiment

- A manager can draft processes
- A manager can publish processes
- A manager can set a default shipping process and all order created will follow that process by default
- A manager can set a default receiving process and all shipment received will follow that process by default

- An associate can place orders
- An associate can help a worker do their work, but worker cannot help associate as talking to customer and other departments requires special trainning
- An associate can create an expected shipment

- A worker can change the shipping process of an order
- A worker can set the beginning quantity of a stock
- A worker can adjust the quantity of a stock
- A worker can mark an order as been shipped
- A worker can reserve items for an order
- A worker can reserve specific line items of an order
- A worker can create a backorder of an order
- A worker can create a movement to reserve items to be moved
- A worker can move items between locations
- A worker can change the receiving process of a shipment
- A worker can receive shipments for the warehouse


- Receiving process
- Shipping process
