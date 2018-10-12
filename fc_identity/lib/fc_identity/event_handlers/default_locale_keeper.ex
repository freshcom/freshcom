defmodule FCIdentity.DefaultLocaleKeeper do
  @moduledoc false

  use Commanded.Event.Handler,
    name: "e04b7e24-a659-43d2-a84f-0b9c351c23a3"

  alias FCStateStorage.GlobalStore.DefaultLocaleStore
  alias FCIdentity.AccountCreated

  def handle(%AccountCreated{} = event, _metadata) do
    DefaultLocaleStore.put(event.account_id, event.default_locale)
  end
end