defmodule FCInventory.Order do
  use TypedStruct
  use FCBase, :aggregate

  import UUID

  alias Decimal, as: D
  alias FCInventory.LineItem
  alias FCInventory.{
    OrderCreated,
    OrderMarked,
    StockReservationRequested,
    StockReservationRecorded,
    StockReservationFinished,
    OrderProcessingStarted,
    OrderItemProcessed,
    OrderProcessingFinished
  }

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :customer_id, String.t()
    field :assignee_id, String.t()
    field :location_id, String.t()

    # draft, hold, pending, zero_stock, action_required,
    # ready, picking/packing/checking, completed
    field :status, String.t()
    field :stock_status, String.t()
    field :line_items, map(), default: %{}
    field :tote_ids, [String.t()], default: []
    field :package_ids, [String.t()], default: []

    field :name, String.t()
    field :email, String.t()
    field :phone_number, String.t()

    field :shipping_address_line_one, String.t()
    field :shipping_address_line_two, String.t()
    field :shipping_address_city, String.t()
    field :shipping_address_province, String.t()
    field :shipping_address_country_code, String.t()
    field :shipping_address_postal_code, String.t()
  end

  def create(fields, staff) do
    merge_to(fields, %OrderCreated{order_id: uuid4(), staff_id: staff.id})
  end

  def mark(order, status, staff) do
    order
    |> merge_to(%OrderMarked{original_status: order.status})
    |> Map.put(:status, status)
    |> Map.put(:staff_id, staff.id)
    |> Map.put(:order_id, order.id)
  end

  def update_shipping_address(order, address, staff) do

  end

  def update_contact_info(order, contact_info, staff) do

  end

  def request_stock_reservation(order, staff) do
    order
    |> merge_to(%StockReservationRequested{})
    |> Map.put(:staff_id, staff.id)
    |> Map.put(:order_id, order.id)
  end

  def record_stock_reservation(order, sku, serial_number, quantity, staff) do
    line_item = get_line_item(order, sku, serial_number)
    do_record_stock_reservation(order, line_item, quantity, staff)
  end

  defp do_record_stock_reservation(_, nil, _, _), do: {:error, {:not_found, :line_item}}

  defp do_record_stock_reservation(order, line_item, quantity, staff) do
    order
    |> merge_to(%StockReservationRecorded{})
    |> Map.put(:staff_id, staff.id)
    |> Map.put(:order_id, order.id)
    |> Map.put(:sku, line_item.sku)
    |> Map.put(:serial_number, line_item.serial_number)
    |> Map.put(:quantity, quantity)
  end

  def finish_stock_reservation(order, staff) do
    order
    |> merge_to(%StockReservationFinished{original_status: order.status})
    |> Map.put(:status, stock_status(order))
    |> Map.put(:staff_id, staff.id)
    |> Map.put(:order_id, order.id)
  end

  defp stock_status(%{line_items: line_items} = order) do
    quantity_total = LineItem.quantity(line_items)
    quantity_reserved = LineItem.quantity_reserved(line_items)

    cond do
      D.cmp(quantity_reserved, D.new(0)) == :eq ->
        "none_reserved"

      D.cmp(quantity_reserved, quantity_total) == :lt ->
        "partially_reserved"

      D.cmp(quantity_reserved, quantity_total) == :eq ->
        "reserved"

      D.cmp(quantity_reserved, quantity_total) == :gt ->
        "over_reserved"
    end
  end

  def start_processing(order, status, staff) do
    order
    |> merge_to(%OrderProcessingStarted{original_status: order.status})
    |> Map.put(:status, status)
    |> Map.put(:staff_id, staff.id)
    |> Map.put(:order_id, order.id)
  end

  def process_item(order, sku, serial_number, quantity, staff) do
    line_item = get_line_item(order, sku, serial_number)
    do_process_item(order, line_item, quantity, staff)
  end

  defp do_process_item(_, nil, _, _), do: {:error, {:not_found, :line_item}}

  defp do_process_item(order, line_item, quantity, staff) do
    order
    |> merge_to(%OrderItemProcessed{})
    |> Map.put(:staff_id, staff.id)
    |> Map.put(:order_id, order.id)
    |> Map.put(:sku, line_item.sku)
    |> Map.put(:serial_number, line_item.serial_number)
    |> Map.put(:quantity, quantity)
  end

  defp get_line_item(%{line_items: line_items}, sku, serial_number) do
    LineItem.get(line_items, sku, serial_number)
  end

  def finish_processing(order, status, staff) do
    order
    |> merge_to(%OrderProcessingFinished{original_status: order.status})
    |> Map.put(:status, status)
    |> Map.put(:staff_id, staff.id)
    |> Map.put(:order_id, order.id)
  end

  def add_line_item(order, fields, staff) do

  end

  def update_line_item(order, lid, fields, staff) do

  end

  def delete_line_item(order, lid, staff) do

  end

  def cancel(order, staff) do

  end

  def apply(order, %OrderCreated{} = event) do
    %{order | id: event.order_id}
    |> merge(event)
  end

  def apply(order, %OrderMarked{} = event) do
    %{order | status: event.status}
  end

  def apply(order, %StockReservationRequested{} = event) do
    %{order | stock_status: "reservation_requested"}
  end

  def apply(order, %StockReservationRecorded{} = event) do
    replace_line_item(order, event.sku, event.serial_number, &(LineItem.record_reserved(&1, event.quantity)))
  end

  def apply(order, %StockReservationFinished{} = event) do
    %{order | stock_status: event.status}
  end

  def apply(%{line_items: line_items} = order, %OrderProcessingStarted{} = event) do
    line_items = Enum.map(line_items, &LineItem.reset_processed/1)
    %{
      order
      | status: event.status,
        line_items: line_items
    }
  end

  def apply(order, %OrderItemProcessed{} = event) do
    replace_line_item(order, event.sku, event.serial_number, &(LineItem.record_processed(&1, event.quantity)))
  end

  def apply(order, %OrderProcessingFinished{} = event) do
    %{order | status: event.status}
  end

  defp replace_line_item(%{line_items: line_items} = order, sku, serial_number, func) do
    line_item =
      order
      |> get_line_item(sku, serial_number)
      |> func.()

    index = LineItem.find_index(line_items, line_item)
    line_items = List.replace_at(line_items, index, line_item)

    %{order | line_items: line_items}
  end
end