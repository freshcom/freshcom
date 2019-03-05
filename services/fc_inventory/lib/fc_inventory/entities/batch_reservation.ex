defmodule FCInventory.BatchReservation do
  use TypedStruct

  import FCSupport.Normalization

  alias Decimal, as: D

  @derive Jason.Encoder

  typedstruct do
    field :account_id, String.t()
    field :movement_id, String.t()
    field :batch_id, String.t()

    field :status, String.t(), default: "reserved"
    field :quantity, Decimal.t()
    field :quantity_fulfilled, Decimal.t(), default: D.new(0)
  end

  def deserialize(map) do
    %{struct(%__MODULE__{}, atomize_keys(map)) | quantity: D.new(map["quantity"])}
  end

  def decrease(rsv, quantity) do
    new_quantity = D.sub(rsv.quantity, quantity)
    %{rsv | quantity: new_quantity}
  end
end
