defmodule FCInventory.LineItemUpdated do
  use FCBase, :event

  alias Decimal, as: D

  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :request_id, String.t()
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()
    field :account_id, String.t()

    field :effective_keys, [String.t()], default: []
    field :original_fields, map(), default: %{}
    field :locale, String.t()

    field :movement_id, String.t()
    field :stockable_id, String.t()
    field :quantity, Decimal.t()

    field :name, String.t()
    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
    field :translations, map()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.LineItemUpdated do
  import FCSupport.Normalization

  alias Decimal, as: D

  def decode(event) do
    %{
      event
      | quantity: D.new(event.quantity),
        effective_keys: atomize_list(event.effective_keys),
        original_fields: decode_ofields(event.original_fields)
    }
  end

  def decode_ofields(%{"quantity" => _} = ofields) do
    ofields = atomize_keys(ofields)
    %{ofields | quantity: D.new(ofields.quantity)}
  end

  def decode_ofields(ofields) do
    atomize_keys(ofields)
  end
end

