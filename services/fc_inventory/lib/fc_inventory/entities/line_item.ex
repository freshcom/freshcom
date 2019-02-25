defmodule FCInventory.LineItem do
  use TypedStruct

  import FCSupport.Normalization

  alias Decimal, as: D

  @derive Jason.Encoder

  typedstruct do
    field :movement_id, String.t()
    field :quantity, Decimal.t()
    field :quantity_processed, map(), default: %{}

    field :name, String.t()
    field :status, String.t(), default: "pending"
    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map(), default: %{}
    field :translations, map(), default: %{}
  end

  def translatable_fields do
    [
      :name,
      :caption,
      :description,
      :custom_data
    ]
  end

  def add_quantity_processed(line_item, nil, _), do: line_item

  def add_quantity_processed(%{quantity_processed: qp} = line_item, quantity, status) do
    current_quantity = qp[status] || D.new(0)
    new_quantity = D.add(current_quantity, quantity)

    new_qp =
      case D.cmp(new_quantity, D.new(0)) do
        :eq -> Map.drop(qp, [status])

        _ -> Map.put(qp, status, new_quantity)
      end

    %{line_item | quantity_processed: new_qp}
  end

  def deserialize(map) do
    quantity_processed =
      Enum.reduce(map["quantity_processed"], %{}, fn {k, v}, m ->
        Map.put(m, k, D.new(v))
      end)

    %{
      struct(%__MODULE__{}, atomize_keys(map))
      | quantity: D.new(map["quantity"]),
        quantity_processed: quantity_processed
    }
  end
end
