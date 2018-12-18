defmodule FCIdentity.TestAccountSync do
  @moduledoc false
  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:639c6640-d45d-41a0-b240-490282ab5984",
    router: FCIdentity.Router

  alias FCSupport.Struct
  alias FCIdentity.{TestAccountIdStore}
  alias FCIdentity.{AccountCreated, AccountInfoUpdated, AccountClosed}
  alias FCIdentity.{CreateAccount, UpdateAccountInfo, CloseAccount}

  defstruct []

  def interested?(%AccountCreated{test_account_id: account_id, mode: "live"}), do: {:start, account_id}
  def interested?(%AccountCreated{account_id: account_id, mode: "test"}), do: {:stop, account_id}

  def interested?(%AccountInfoUpdated{account_id: account_id}) do
    test_account_id = TestAccountIdStore.get(account_id)

    if test_account_id do
      {:start, test_account_id}
    else
      {:stop, account_id}
    end
  end

  def interested?(%AccountClosed{test_account_id: account_id, mode: "live"}), do: {:start, account_id}
  def interested?(%AccountClosed{account_id: account_id, mode: "test"}), do: {:stop, account_id}

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

  def handle(_, %AccountInfoUpdated{account_id: account_id} = event) do
    test_account_id = TestAccountIdStore.get(account_id)

    %UpdateAccountInfo{}
    |> Struct.merge(event)
    |> Map.put(:account_id, test_account_id)
    |> Map.put(:requester_role, "system")
    |> Map.put(:handle, "#{event.handle}-test")
  end

  def handle(_, %AccountClosed{test_account_id: account_id}) do
    %CloseAccount{requester_role: "system", account_id: account_id}
  end
end