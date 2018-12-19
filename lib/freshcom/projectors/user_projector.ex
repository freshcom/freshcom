defmodule Freshcom.UserProjector do
  @moduledoc false

  use Freshcom.Projector
  use Commanded.Projections.Ecto, name: "projector:9708460c-a25a-4a14-b049-ea78af279746"

  alias Ecto.Changeset
  alias Freshcom.Repo
  alias Freshcom.User
  alias FCIdentity.{
    UserRegistered,
    UserAdded,
    UserInfoUpdated,
    DefaultAccountChanged,
    UserRoleChanged,
    PasswordResetTokenGenerated,
    PasswordChanged,
    UserDeleted
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

  project(%DefaultAccountChanged{} = event, _) do
    changeset =
      User
      |> Repo.get(event.user_id)
      |> Changeset.change(default_account_id: event.default_account_id)

    Multi.update(multi, :user, changeset)
  end

  project(%UserRoleChanged{} = event, _) do
    changeset =
      User
      |> Repo.get(event.user_id)
      |> Changeset.change(role: event.role)

    Multi.update(multi, :user, changeset)
  end

  project(%PasswordResetTokenGenerated{} = event, _) do
    changeset =
      User
      |> Repo.get(event.user_id)
      |> Changeset.change(
        password_reset_token: event.token,
        password_reset_token_expires_at: NaiveDateTime.from_iso8601!(event.expires_at)
      )

    Multi.update(multi, :user, changeset)
  end

  project(%PasswordChanged{} = event, metadata) do
    changeset =
      User
      |> Repo.get(event.user_id)
      |> Changeset.change(
        password_hash: event.new_password_hash,
        password_reset_token: nil,
        password_reset_token_expires_at: nil,
        password_updated_at: metadata.created_at
      )

    Multi.update(multi, :user, changeset)
  end

  project(%UserDeleted{} = event, _) do
    user = Repo.get(User, event.user_id)
    Multi.delete(multi, :user, user)
  end

  def after_update(_, _, changes) do
    PubSub.broadcast(PubSubServer, Projector.topic(), {:projected, __MODULE__, changes.user})
    :ok
  end
end