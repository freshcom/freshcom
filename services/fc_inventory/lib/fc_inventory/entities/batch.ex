defmodule FCInventory.Batch do
  use TypedStruct

  alias Decimal, as: D

  typedstruct do
    field :storage_id, String.t()

    field :status, String.t(), default: "active"
    field :number, String.t()
    field :label, String.t()
    field :quantity_on_hand, Decimal.t(), default: D.new(0)
    field :quantity_reserved, Decimal.t(), default: D.new(0)
    field :expires_at, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
    field :translations, map(), default: %{}
  end

  def translatable_fields do
    [
      :caption,
      :description,
      :custom_data
    ]
  end
end
