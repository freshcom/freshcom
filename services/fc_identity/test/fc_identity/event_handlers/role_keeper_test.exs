defmodule FCIdentity.RoleKeeperTest do
  use FCIdentity.UnitCase, async: true

  alias FCStateStorage.GlobalStore.UserRoleStore
  alias FCIdentity.RoleKeeper
  alias FCIdentity.UserAdded

  test "handle UserAdded" do
    event = %UserAdded{user_id: uuid4(), account_id: uuid4(), role: "owner"}

    :ok = RoleKeeper.handle(event, %{})

    assert UserRoleStore.get(event.user_id, event.account_id) == "owner"
  end
end