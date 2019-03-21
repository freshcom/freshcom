defmodule FCInventory.Entry do
  use TypedStruct

  import FCSupport.Normalization

  @derive Jason.Encoder

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :transaction_id, String.t()
    field :serial_number, String.t()

    field :status, String.t(), default: "planned"
    field :quantity, Decimal.t()
    field :expected_commit_date, DateTime.t()
  end

  def deserialize(map) do
    %{
      struct(%__MODULE__{}, atomize_keys(map))
      | quantity: Decimal.new(map["quantity"])
    }
  end
end
