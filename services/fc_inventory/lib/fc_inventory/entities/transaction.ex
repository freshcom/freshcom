defmodule FCInventory.Transaction do
  use TypedStruct

  import FCSupport.Normalization

  alias Decimal, as: D

  @derive Jason.Encoder

  typedstruct do
    field :source_batch_id, String.t()
    field :destination_batch_id, String.t()

    field :status, String.t(), default: "reserved"
    field :quantity, Decimal.t()
    field :quantity_processed, Decimal.t(), default: D.new(0)
  end

  def deserialize(map) do
    %{struct(%__MODULE__{}, atomize_keys(map)) | quantity: D.new(map["quantity"])}
  end
end
