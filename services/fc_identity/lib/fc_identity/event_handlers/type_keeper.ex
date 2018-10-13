defmodule FCIdentity.TypeKeeper do
  @moduledoc false

  use Commanded.Event.Handler,
    name: "a64a6d5d-fc8c-4911-9715-d5e0ecdc9a82"

  alias FCStateStorage.GlobalStore.UserTypeStore
  alias FCIdentity.UserAdded

  def handle(%UserAdded{} = event, _metadata) do
    UserTypeStore.put(event.user_id, event.type)
  end
end