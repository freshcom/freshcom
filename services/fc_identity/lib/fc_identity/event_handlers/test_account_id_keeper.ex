defmodule FCIdentity.TestAccountIdKeeper do
  @moduledoc false

  use Commanded.Event.Handler,
    name: "24c91612-770b-499f-bbbc-f5f9ac05e995"

  alias FCIdentity.TestAccountIdStore
  alias FCIdentity.AccountCreated

  def handle(%AccountCreated{account_id: aid, test_account_id: taid}, _) when not is_nil(taid) do
    TestAccountIdStore.put(aid, taid)
  end
end