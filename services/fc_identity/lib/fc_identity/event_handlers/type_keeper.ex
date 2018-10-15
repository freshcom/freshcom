defmodule FCIdentity.TypeKeeper do
  @moduledoc false

  use Commanded.Event.Handler,
    name: "a64a6d5d-fc8c-4911-9715-d5e0ecdc9a82"

  alias FCStateStorage.GlobalStore.UserTypeStore
  alias FCIdentity.{UserRegistered, UserAdded}

  def handle(%UserRegistered{} = event, _) do
    UserTypeStore.put(event.user_id, "standard")
  end

  def handle(%UserAdded{} = event, _) do
    UserTypeStore.put(event.user_id, "managed")
  end
end