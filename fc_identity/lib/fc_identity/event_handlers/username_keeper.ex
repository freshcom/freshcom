defmodule FCIdentity.UsernameKeeper do
  use Commanded.Event.Handler,
    name: "750e4669-c458-472a-a9a3-6b00d27ec14f"

  alias FCIdentity.UsernameStore
  alias FCIdentity.UserAdded

  def handle(%UserAdded{} = event, _metadata) do
    UsernameStore.put(event)
  end
end