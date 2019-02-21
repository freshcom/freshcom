defmodule FCInventory.LineItem do
  use TypedStruct

  import FCSupport.Normalization

  alias Decimal, as: D
  alias FCInventory.{
    LineItemCreated,
    LineItemUpdated,
    LineItemMarked
  }

  @derive Jason.Encoder

  typedstruct do
    field :movement_id, String.t()
    field :stockable_id, String.t()
    field :cause_id, String.t()
    field :cause_type, String.t()
    field :quantity, Decimal.t()
    field :quantity_processed, Decimal.t(), default: D.new(0)

    field :name, String.t()
    field :status, String.t(), default: "pending"
    field :number, String.t()
    field :label, String.t()

    field :transactions, map(), default: %{}

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

  def deserialize(map) do
    %{
      struct(%__MODULE__{}, atomize_keys(map))
      | quantity: D.new(map["quantity"]),
        quantity_processed: D.new(map["quantity_processed"])
    }
  end
end
