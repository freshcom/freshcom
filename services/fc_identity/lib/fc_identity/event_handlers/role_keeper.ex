defmodule FCIdentity.RoleKeeper do
  @moduledoc false

  use Commanded.Event.Handler,
    name: "7acce566-f170-4b36-a1da-7655f67c65f8"

  alias FCStateStorage.GlobalStore.UserRoleStore
  alias FCIdentity.{UserAdded, UserRoleChanged}

  def handle(%UserAdded{} = event, _) do
    UserRoleStore.put(event.user_id, event.account_id, event.role)
  end

  def handle(%UserRoleChanged{} = event, _) do
    UserRoleStore.put(event.user_id, event.account_id, event.role)
  end
end