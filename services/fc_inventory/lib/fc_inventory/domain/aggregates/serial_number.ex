defmodule FCInventory.SerialNumber do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCInventory.{SerialNumberAdded}

  typedstruct do
    field :remove_at, DateTime.t()
  end

  def translatable_fields do
    [
      :name,
      :caption,
      :description,
      :custom_data
    ]
  end

  def apply(%{} = state, %SerialNumberAdded{} = event) do
    merge(state, event)
  end
end
