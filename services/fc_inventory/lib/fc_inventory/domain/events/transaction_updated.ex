defmodule FCInventory.TransactionUpdated do
  use FCBase, :event

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :account_id, String.t()
    field :staff_id, String.t()

    field :effective_keys, [atom()]
    field :original_fields, map(), default: %{}

    field :transaction_id, String.t()
    field :movement_id, String.t()
    field :serial_number, String.t()

    field :quantity, String.t()
    field :expected_commit_date, DateTime.t()

    field :summary, String.t()
    field :description, String.t()
    field :label, String.t()
  end

  defimpl Commanded.Serialization.JsonDecoder do
    import FCSupport.Normalization

    def decode(event) do
      %{
        event
        | quantity: decode_quantity(event.quantity),
          effective_keys: atomize_list(event.effective_keys),
          original_fields: decode_ofields(event.original_fields)
      }
    end

    def decode_quantity(nil), do: nil
    def decode_quantity(n), do: Decimal.new(n)

    def decode_ofields(%{"quantity" => _} = ofields) do
      ofields = atomize_keys(ofields)
      %{ofields | quantity: decode_quantity(ofields.quantity)}
    end

    def decode_ofields(ofields) do
      atomize_keys(ofields)
    end
  end
end