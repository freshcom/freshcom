defmodule FCInventory.Storage do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCInventory.{StorageAdded, StorageUpdated, StorageDeleted}

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :root_location_id, String.t()
    field :stock_location_id, String.t()

    field :status, String.t()
    field :type, String.t()
    field :number, String.t()

    field :name, String.t()
    field :label, String.t()

    field :address_line_one, String.t()
    field :address_line_two, String.t()
    field :address_city, String.t()
    field :address_region_code, String.t()
    field :address_country_code, String.t()

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

  def apply(%{} = state, %StorageAdded{} = event) do
    %{state | id: event.storage_id}
    |> merge(event)
  end

  def apply(state, %StorageUpdated{} = event) do
    state
    |> cast(event)
    |> apply_changes()
  end

  def apply(state, %StorageDeleted{}) do
    %{state | status: "deleted"}
  end
end
