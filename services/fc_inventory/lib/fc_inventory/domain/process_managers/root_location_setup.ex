defmodule FCInventory.RootLocationSetup do
  @moduledoc false
  use TypedStruct

  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:6cd953e4-3af5-4bb9-a76b-d30c92e75d7a",
    router: FCInventory.Router

  alias FCInventory.{
    AddLocation
  }

  alias FCInventory.{
    StorageAdded,
    LocationAdded
  }

  @derive Jason.Encoder
  defstruct []

  def interested?(%StorageAdded{} = event), do: {:start, event.root_location_id}
  def interested?(%LocationAdded{} = event), do: {:stop, event.location_id}
  def interested?(_), do: false

  def handle(_, %StorageAdded{} = event) do
    %AddLocation{
      requester_role: "system",
      account_id: event.account_id,
      location_id: event.root_location_id,
      type: "view",
      name: event.short_name
    }
  end
end
