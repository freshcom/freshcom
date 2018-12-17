defmodule FCIdentity.Keeper do
  use Commanded.Event.Handler,
    name: "event-handler:f25377d2-2658-4357-9648-1c429d65965b",
    consistency: :strong

  alias FCStateStorage.GlobalStore.{DefaultLocaleStore, UserTypeStore, UserRoleStore, AppStore}
  alias FCIdentity.TestAccountIdStore

  alias FCIdentity.{UserRegistered, UserAdded, UserRoleChanged}
  alias FCIdentity.{AccountCreated}
  alias FCIdentity.AppAdded

  def handle(%AccountCreated{} = event, _) do
    DefaultLocaleStore.put(event.account_id, event.default_locale)
    UserRoleStore.put(event.owner_id, event.account_id, "owner")

    if event.mode == "live" do
      TestAccountIdStore.put(event.test_account_id, event.account_id)
    end

    :ok
  end

  def handle(%UserRegistered{} = event, _) do
    UserTypeStore.put(event.user_id, "standard")
  end

  def handle(%UserAdded{} = event, _) do
    UserTypeStore.put(event.user_id, "managed")
    keep_role(event)
  end

  def handle(%UserRoleChanged{} = event, _) do
    keep_role(event)
  end

  def handle(%AppAdded{} = event, _) do
    AppStore.put(event.app_id, event.type, event.account_id)
  end

  defp keep_role(%et{} = event) when et in [UserAdded, UserRoleChanged] do
    UserRoleStore.put(event.user_id, event.account_id, event.role)
    test_account_id = TestAccountIdStore.get(event.account_id)

    if test_account_id do
      UserRoleStore.put(event.user_id, test_account_id, event.role)
    end

    :ok
  end
end