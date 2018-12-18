defmodule FCIdentity.Keeper do
  use Commanded.Event.Handler,
    name: "event-handler:f25377d2-2658-4357-9648-1c429d65965b",
    consistency: :strong

  alias FCStateStorage.GlobalStore.{DefaultLocaleStore, UserTypeStore, UserRoleStore, AppStore}
  alias FCIdentity.{TestAccountIdStore, UsernameStore, AccountHandleStore}

  alias FCIdentity.{UserRegistered, UserAdded, UserRoleChanged, UserDeleted}
  alias FCIdentity.{AccountCreated, AccountDeleted}
  alias FCIdentity.{AppAdded, AppDeleted}

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
    put_role(event)
  end

  def handle(%UserRoleChanged{} = event, _) do
    put_role(event)
  end

  def handle(%AppAdded{} = event, _) do
    AppStore.put(event.app_id, event.type, event.account_id)
  end

  def handle(%AccountDeleted{} = event, _) do
    AccountHandleStore.delete(event.handle)

    :ok
  end

  def handle(%UserDeleted{} = event, _) do
    UserTypeStore.delete(event.user_id)
    UserRoleStore.delete(event.user_id, event.account_id)
    UsernameStore.delete(event.username, event.account_id)

    test_account_id = TestAccountIdStore.get(event.account_id)

    if test_account_id do
      UserRoleStore.delete(event.user_id, test_account_id)
    end

    :ok
  end

  def handle(%AppDeleted{} = event, _) do
    AppStore.delete(event.app_id)
  end

  defp put_role(%et{} = event) when et in [UserAdded, UserRoleChanged] do
    UserRoleStore.put(event.user_id, event.account_id, event.role)
    test_account_id = TestAccountIdStore.get(event.account_id)

    if test_account_id do
      UserRoleStore.put(event.user_id, test_account_id, event.role)
    end

    :ok
  end
end