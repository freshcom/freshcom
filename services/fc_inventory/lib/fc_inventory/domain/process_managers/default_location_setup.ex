defmodule FCInventory.DefaultLocationSetup do
  @moduledoc false
  use TypedStruct

  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:3c4a26dd-d14b-4caf-851d-327a6724e992",
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

  def interested?(%StorageAdded{} = event), do: {:start, event.default_location_id}
  def interested?(%LocationAdded{} = event), do: {:stop, event.location_id}
  def interested?(_), do: false

  def handle(_, %StorageAdded{} = event) do
    %AddLocation{
      requester_role: "system",
      account_id: event.account_id,
      parent_id: event.root_location_id,
      location_id: event.default_location_id,
      type: "internal",
      name: "Default"
    }
  end
end
