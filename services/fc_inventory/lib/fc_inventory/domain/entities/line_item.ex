defmodule FCInventory.LineItem do
  use TypedStruct

  import FCSupport.Normalization

  alias Decimal, as: D

  @derive Jason.Encoder
  typedstruct do
    field :sku, String.t()
    field :serial_number, String.t()

    field :quantity, Decimal.t()
    field :quantity_reserved, Decimal.t(), default: Decimal.new(0)
    field :quantity_processed, Decimal.t(), default: Decimal.new(0)

    field :description, String.t()
    field :note, String.t()
  end

  def deserialize(list) when is_list(list) do
    Enum.map(list, &deserialize/1)
  end

  def deserialize(map) when is_map(map) do
    %{
      struct(%__MODULE__{}, atomize_keys(map))
      | quantity: D.new(map["quantity"]),
        quantity_reserved: D.new(map["quantity_reserved"]),
        quantity_processed: D.new(map["quantity_processed"])
    }
  end

  def get(line_items, sku, serial_number) do
    Enum.find(line_items, fn line_item ->
      line_item.sku == sku && line_item.serial_number == serial_number
    end)
  end

  def find_index(line_items, %{sku: sku, serial_number: serial_number}) do
    Enum.find_index(line_items, fn line_item ->
      line_item.sku == sku && line_item.serial_number == serial_number
    end)
  end

  def quantity(line_items) do
    Enum.reduce(line_items, D.new(0), &(D.add(&2, &1.quantity)))
  end

  def quantity_reserved(line_items) do
    Enum.reduce(line_items, D.new(0), &(D.add(&2, &1.quantity_reserved)))
  end

  def record_reserved(line_item, quantity) do
    new_quantity = D.add(line_item.quantity_reserved, quantity)
    %{line_item | quantity_reserved: new_quantity}
  end

  def record_processed(line_item, quantity) do
    new_quantity = D.add(line_item.quantity_processed, quantity)
    %{line_item | quantity_processed: new_quantity}
  end

  def reset_processed(line_item) do
    %{line_item | quantity_processed: D.new(0)}
  end
end