defmodule FCInventory.BatchUpdated do
  use TypedStruct

  @derive Jason.Encoder
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

    field :effective_keys, [String.t()]
    field :original_fields, map()
    field :locale, String.t()

    field :stockable_id, String.t()
    field :batch_id, String.t()

    field :quantity_on_hand, Decimal.t()
    field :expires_at, DateTime.t()

    field :status, String.t()
    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
    field :translations, map()
  end
end

defimpl Commanded.Serialization.JsonDecoder, for: FCInventory.BatchUpdated do
  import FCSupport.Normalization

  alias Decimal, as: D

  def decode(event) do
    %{
      event
      | quantity_on_hand: D.new(event.quantity_on_hand),
        effective_keys: atomize_list(event.effective_keys),
        original_fields: decode_ofields(event.original_fields)
    }
  end

  def decode_ofields(%{"quantity_on_hand" => _} = ofields) do
    ofields = atomize_keys(ofields)
    %{ofields | quantity_on_hand: D.new(ofields.quantity_on_hand)}
  end

  def decode_ofields(ofields) do
    atomize_keys(ofields)
  end
end