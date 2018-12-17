defmodule FCIdentity.Keeper do
  use Commanded.Event.Handler, name: "event-handler:f25377d2-2658-4357-9648-1c429d65965b"

  alias FCStateStorage.GlobalStore.{DefaultLocaleStore, UserRoleStore}
  alias FCIdentity.TestAccountIdStore
  alias FCIdentity.{AccountCreated}

  def handle(%AccountCreated{} = event, _) do
    DefaultLocaleStore.put(event.account_id, event.default_locale)
    UserRoleStore.put(event.owner_id, event.account_id, "owner")

    if event.mode == "live" do
      TestAccountIdStore.put(event.test_account_id, event.account_id)
    end

    :ok
  end
end