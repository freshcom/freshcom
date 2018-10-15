defmodule Freshcom.UserProjector do
  use Freshcom.Projector
  use Commanded.Projections.Ecto, name: "9708460c-a25a-4a14-b049-ea78af279746"

  alias Phoenix.PubSub
  alias Freshcom.PubSubServer
  alias Freshcom.User
  alias FCIdentity.{
    UserRegistered
  }

  project(%UserRegistered{} = event, _metadata) do
    user = struct_merge(%User{id: event.user_id}, event)
    Multi.insert(multi, :user, user)
  end

  def after_update(_, _, changes) do
    PubSub.broadcast(PubSubServer, Projector.topic(), {:projected, __MODULE__, changes.user})
    :ok
  end
end