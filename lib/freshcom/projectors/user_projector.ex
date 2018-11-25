defmodule Freshcom.UserProjector do
  @moduledoc false

  use Freshcom.Projector
  use Commanded.Projections.Ecto, name: "projector:9708460c-a25a-4a14-b049-ea78af279746"

  alias Phoenix.PubSub
  alias Freshcom.{Repo, PubSubServer}
  alias Freshcom.User
  alias FCIdentity.{
    UserRegistered,
    UserAdded,
    UserInfoUpdated,
    UserRoleChanged
  }

  project(%UserRegistered{} = event, _) do
    user = Struct.merge(%User{id: event.user_id, type: "standard"}, event)
    Multi.insert(multi, :user, user)
  end

  project(%UserAdded{} = event, _) do
    user = Struct.merge(%User{id: event.user_id}, event)
    Multi.insert(multi, :user, user)
  end

  project(%UserInfoUpdated{} = event, _) do
    changeset =
      User
      |> Repo.get(event.user_id)
      |> Projection.changeset(event)

    Multi.update(multi, :user, changeset)
  end

  project(%UserRoleChanged{} = event, _) do
    changeset =
      User
      |> Repo.get(event.user_id)
      |> Ecto.Changeset.change(role: event.role)

    Multi.update(multi, :user, changeset)
  end

  def after_update(_, _, changes) do
    PubSub.broadcast(PubSubServer, Projector.topic(), {:projected, __MODULE__, changes.user})
    :ok
  end
end