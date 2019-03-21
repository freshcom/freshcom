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
end
