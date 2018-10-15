defmodule FCIdentity.UsernameKeeper do
  @moduledoc false

  use Commanded.Event.Handler,
    name: "750e4669-c458-472a-a9a3-6b00d27ec14f"

  alias FCIdentity.UsernameStore
  alias FCIdentity.{UserRegistered, UserAdded}

  def handle(%UserRegistered{} = event, _) do
    UsernameStore.put(event.username)
  end

  def handle(%UserAdded{} = event, _) do
    UsernameStore.put(event.username, event.account_id)
  end
end