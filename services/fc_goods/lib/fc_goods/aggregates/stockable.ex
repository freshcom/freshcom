defmodule FCGoods.Stockable do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCGoods.{StockableAdded}

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()

    field :status, String.t()
    field :type, String.t()
    field :name, String.t()
  end

  def apply(%{} = state, %StockableAdded{} = event) do
    %{state | id: event.stockable_id}
    |> merge(event)
  end
end