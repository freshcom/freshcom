defmodule FCIdentity.TestAccountSetup do
  @moduledoc false
  use Commanded.ProcessManagers.ProcessManager,
    name: "639c6640-d45d-41a0-b240-490282ab5984",
    router: FCIdentity.Router

  alias FCIdentity.AccountCreated
  alias FCIdentity.CreateAccount

  defstruct []

  def interested?(%AccountCreated{account_id: account_id, mode: "live"}), do: {:start, account_id}
  def interested?(%AccountCreated{live_account_id: live_account_id, mode: "test"}), do: {:stop, live_account_id}
  def interested?(_), do: false

  def handle(_, %AccountCreated{} = event) do
    %CreateAccount{
      requester_role: "system",
      account_id: event.test_account_id,
      owner_id: event.owner_id,
      mode: "test",
      live_account_id: event.account_id,
      name: event.name,
      default_locale: event.default_locale
    }
  end
end