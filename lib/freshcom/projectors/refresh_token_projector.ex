defmodule Freshcom.RefreshTokenProjector do
  @moduledoc false

  use Freshcom.Projector
  use Commanded.Projections.Ecto, name: "projector:431b1a65-b05b-4eb7-908c-b3accfd0b017"

  import UUID

  alias Phoenix.PubSub
  alias Freshcom.PubSubServer
  alias Freshcom.RefreshToken
  alias FCIdentity.{
    AccountCreated,
    UserAdded
  }

  project(%AccountCreated{} = event, _metadata) do
    prt = %RefreshToken{id: uuid4(), account_id: event.account_id}
    urt = %RefreshToken{id: uuid4(), user_id: event.owner_id, account_id: event.account_id}

    multi
    |> Multi.insert(:prt, prt)
    |> Multi.insert(:urt, urt)
  end

  project(%UserAdded{} = event, _metadata) do
    urt = %RefreshToken{id: uuid4(), user_id: event.user_id, account_id: event.account_id}
    Multi.insert(multi, :urt, urt)
  end

  def after_update(_, _, changes) do
    PubSub.broadcast(PubSubServer, Projector.topic(), {:projected, __MODULE__, changes.urt})
    :ok
  end
end