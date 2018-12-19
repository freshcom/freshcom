defmodule Freshcom.AccountProjector do
  @moduledoc false

  use Freshcom.Projector
  use Commanded.Projections.Ecto, name: "projector:b1c31ad3-44f9-43ce-a715-3b9da1926992"

  alias Ecto.Changeset
  alias Freshcom.Repo
  alias Freshcom.Account
  alias FCIdentity.{
    AccountCreated,
    AccountInfoUpdated,
    AccountClosed
  }

  project(%AccountCreated{} = event, _metadata) do
    account = Struct.merge(%Account{id: event.account_id}, event)
    Multi.insert(multi, :account, account)
  end

  project(%AccountInfoUpdated{} = event, _) do
    changeset =
      Account
      |> Repo.get(event.account_id)
      |> Projection.changeset(event)

    Multi.update(multi, :account, changeset)
  end

  project(%AccountClosed{} = event, _) do
    changeset =
      Account
      |> Repo.get(event.account_id)
      |> Changeset.change(status: "closed", handle: event.handle)

    Multi.update(multi, :account, changeset)
  end

  def after_update(_, _, changes) do
    PubSub.broadcast(PubSubServer, Projector.topic(), {:projected, __MODULE__, changes.account})
    :ok
  end
end