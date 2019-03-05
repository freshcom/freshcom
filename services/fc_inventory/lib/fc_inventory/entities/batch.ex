defmodule FCInventory.Batch do
  use TypedStruct

  import UUID
  import FCSupport.Normalization

  alias Decimal, as: D
  alias FCInventory.BatchReservation

  typedstruct do
    field :storage_id, String.t()

    field :status, String.t(), default: "active"
    field :quantity_on_hand, Decimal.t(), default: D.new(0)
    field :quantity_reserved, Decimal.t(), default: D.new(0)
    field :expires_at, DateTime.t()
    field :reservations, map(), default: %{}

    field :number, String.t()
    field :label, String.t()

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

  def deserialize(map) do
    %{struct(%__MODULE__{}, atomize_keys(map)) | quantity_on_hand: D.new(map["quantity_on_hand"])}
  end

  def is_available(%{status: "active"} = batch) do
    cond do
      is_nil(batch.expires_at) || Timex.before?(Timex.now(), batch.expires_at) ->
        D.cmp(batch.quantity_on_hand, batch.quantity_reserved) == :gt

      true ->
        false
    end
  end

  def is_available(_), do: false

  def reservations(%{reservations: all}, movement_id) do
    Enum.reduce(all, %{}, fn {id, rsv}, reservations ->
      if rsv.movement_id == movement_id do
        Map.put(reservations, id, rsv)
      else
        reservations
      end
    end)
  end

  def add_reservation(batch, %{status: "fulfilled"}), do: batch

  def add_reservation(%{reservations: reservations} = batch, rsv) do
    reservations = Map.put(reservations, uuid4(), rsv)
    quantity_reserved = D.add(batch.quantity_reserved, rsv.quantity)

    %{
      batch
      | reservations: reservations,
        quantity_reserved: quantity_reserved
    }
  end

  def decrease_reservation(%{reservations: reservations} = batch, rsv_id, quantity) do
    rsv = BatchReservation.decrease(reservations[rsv_id], quantity)
    reservations = Map.put(reservations, rsv_id, rsv)
    quantity_reserved = D.sub(batch.quantity_reserved, quantity)

    %{
      batch
      | reservations: reservations,
        quantity_reserved: quantity_reserved
    }
  end
end
