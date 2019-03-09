defmodule FCInventory.LocationHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.LocationPolicy

  alias FCInventory.{AddLocation}
  alias FCInventory.{LocationAdded}
  alias FCInventory.Location

  def handle(%Location{id: nil} = state, %AddLocation{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%LocationAdded{})
    |> unwrap_ok()
  end

  def handle(%Location{id: _}, %AddLocation{}) do
    {:error, {:already_exist, :location}}
  end

  def handle(%{id: nil}, _), do: {:error, {:not_found, :location}}
  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :location}}

  # def handle(state, %UpdateLocation{} = cmd) do
  #   default_locale = FCStateLocation.GlobalStore.DefaultLocaleStore.get(state.account_id)
  #   translatable_fields = FCInventory.Location.translatable_fields()

  #   cmd
  #   |> authorize(state)
  #   ~> merge_to(%LocationUpdated{})
  #   ~> put_translations(state, translatable_fields, default_locale)
  #   ~> put_original_fields(state)
  #   |> unwrap_ok()
  # end

  # def handle(state, %DeleteLocation{} = cmd) do
  #   cmd
  #   |> authorize(state)
  #   ~> merge_to(%LocationDeleted{})
  #   |> unwrap_ok()
  # end
end
