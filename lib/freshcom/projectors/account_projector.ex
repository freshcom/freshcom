defmodule Freshcom.AccountProjector do
  use Freshcom.Projector
  use Commanded.Projections.Ecto, name: "b1c31ad3-44f9-43ce-a715-3b9da1926992"

  alias Freshcom.Account
  alias FCIdentity.{
    AccountCreated,
    AccountInfoUpdated
  }

  project(%AccountCreated{} = event, _metadata) do
    changeset = change(%Account{id: event.account_id}, Map.from_struct(event))
    Multi.insert(multi, :account, changeset)
  end
end