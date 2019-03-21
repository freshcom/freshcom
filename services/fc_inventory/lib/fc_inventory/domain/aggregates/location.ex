defmodule FCInventory.Location do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCInventory.{LocationAdded}

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()

    field :status, String.t()
    field :type, String.t()
    field :number, String.t()

    field :name, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
    field :translations, map()
  end

  def translatable_fields do
    [
      :name,
      :caption,
      :description,
      :custom_data
    ]
  end

  def apply(%{} = state, %LocationAdded{} = event) do
    %{state | id: event.location_id}
    |> merge(event)
  end
end
