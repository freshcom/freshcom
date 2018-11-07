defmodule FCIdentity.RoleKeeper do
  @moduledoc false

  use Commanded.Event.Handler,
    name: "7acce566-f170-4b36-a1da-7655f67c65f8"

  alias FCStateStorage.GlobalStore.UserRoleStore
  alias FCIdentity.TestAccountIdStore
  alias FCIdentity.{AccountCreated, UserAdded, UserRoleChanged}

  def handle(%AccountCreated{} = event, _) do
    UserRoleStore.put(event.owner_id, event.account_id, "owner")
  end

  def handle(%et{} = event, _) when et in [UserAdded, UserRoleChanged] do
    UserRoleStore.put(event.user_id, event.account_id, event.role)
    test_account_id = TestAccountIdStore.get(event.account_id)

    if test_account_id do
      UserRoleStore.put(event.user_id, test_account_id, event.role)
    end

    :ok
  end
end