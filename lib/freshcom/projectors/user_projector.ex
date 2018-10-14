defmodule Freshcom.UserProjector do
  use Freshcom.Projector
  use Commanded.Projections.Ecto, name: "9708460c-a25a-4a14-b049-ea78af279746"

  alias Freshcom.User
  alias FCIdentity.{
    UserAdded
  }

  project(%UserAdded{} = event, _metadata) do
    changeset = change(%User{id: event.user_id}, Map.from_struct(event))
    Multi.insert(multi, :user, changeset)
  end
end