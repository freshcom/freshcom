defmodule FCIdentity.RoleKeeper do
  use Commanded.Event.Handler,
    name: "7acce566-f170-4b36-a1da-7655f67c65f8"

  alias FCStateStorage.GlobalStore.RoleStore
  alias FCIdentity.{UserAdded, UserRoleChanged}

  def handle(%UserAdded{} = event, _) do
    RoleStore.put(event.user_id, event.account_id, event.role)
  end
end