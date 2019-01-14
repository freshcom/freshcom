defmodule FCGoods.Stockable do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCGoods.{StockableAdded}

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :avatar_id, String.t()

    field :status, String.t()
    field :code, String.t()
    field :name, String.t()
    field :label, String.t()

    field :print_name, String.t()
    field :unit_of_measure, String.t()
    field :specification, String.t()

    field :variable_weight, boolean()
    field :weight, Decimal.t()
    field :weight_unit, String.t()

    field :storage_type, String.t()
    field :storage_size, integer()
    field :storage_description, String.t()
    field :stackable, boolean()

    field :width, Decimal.t()
    field :length, Decimal.t()
    field :height, Decimal.t()
    field :dimension_unit, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
    field :translations, map()
  end

  def apply(%{} = state, %StockableAdded{} = event) do
    %{state | id: event.stockable_id}
    |> merge(event)
  end
end