defmodule FCInventory.Fixture do
  import UUID
  import FCBase.RouterCase

  alias Decimal, as: D
  alias FCInventory.{Stock, StockId}
  alias FCInventory.{SerialNumberStore, LocationStore}
  alias FCInventory.TransactionDrafted

  def serial_number(account_id, data \\ %{}) do
    sn = Faker.String.base64()
    SerialNumberStore.put(account_id, sn, data)
    sn
  end

  def location_id(account_id, data \\ %{}) do
    location_id = uuid4()
    data = Map.merge(%{type: "internal", output_strategy: "fefo"}, data)
    LocationStore.put(account_id, location_id, data)
    location_id
  end

  def draft_transaction(source_type, destination_type, opts \\ []) do
    account_id = uuid4()
    sku_id = uuid4()
    source_id = location_id(account_id, %{type: source_type})
    destination_id = location_id(account_id, %{type: destination_type})
    txn_id = uuid4()

    drafted = %TransactionDrafted{
      sku_id: sku_id,
      source_id: source_id,
      destination_id: destination_id,
      quantity: opts[:quantity] || D.new(5)
    }

    events =
      drafted
      |> List.wrap()
      |> Kernel.++(opts[:events] || [])
      |> Enum.map(fn event ->
        %{event | account_id: account_id, transaction_id: txn_id}
      end)

    to_streams(:transaction_id, "inventory-transaction-", events)

    %{
      id: txn_id,
      account_id: account_id,
      sku_id: sku_id,
      source_id: source_id,
      destination_id: destination_id
    }
  end

  def add_entry(account_id, stock_id, events) do
    events = Enum.map(events, fn event ->
      %{
        event
        | account_id: account_id,
          stock_id: stock_id,
          entry_id: event.entry_id || uuid4()
      }
    end)
    to_streams(:stock_id, "inventory-stock-", events)
  end

  def stock_id(:src, %{sku: sku, source_id: source_id}) do
    %StockId{sku: sku, location_id: source_id}
  end

  def stock_id(:dst, %{sku: sku, destination_id: destination_id}) do
    %StockId{sku: sku, location_id: destination_id}
  end
end