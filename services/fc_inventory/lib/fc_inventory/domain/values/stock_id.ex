defmodule FCInventory.StockId do
  use TypedStruct

  @derive Jason.Encoder

  typedstruct do
    field :sku_id, String.t(), enforce: true
    field :location_id, String.t(), enforce: true
  end

  def from(%{"sku_id" => sku_id, "location_id" => location_id}) do
    %__MODULE__{sku_id: sku_id, location_id: location_id}
  end

  defimpl String.Chars do
    def to_string(stock_id), do: "#{stock_id.sku_id}/#{stock_id.location_id}"
  end

  defimpl Vex.Blank do
    def blank?(_) do
      false
    end
  end
end