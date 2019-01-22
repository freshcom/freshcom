defmodule Freshcom.AppProjector do
  @moduledoc false

  use Freshcom.Projector
  use Commanded.Projections.Ecto, name: "projector:85f6535c-ca64-4fb9-826d-fedf332472b2"

  alias Freshcom.App
  alias FCIdentity.{
    AppAdded,
    AppUpdated,
    AppDeleted
  }

  project(%AppAdded{} = event, _metadata) do
    app = Struct.merge(%App{id: event.app_id}, event)
    Multi.insert(multi, :app, app)
  end

  project(%AppUpdated{} = event, _) do
    changeset =
      App
      |> Repo.get(event.app_id)
      |> Projection.changeset(event)

    Multi.update(multi, :app, changeset)
  end

  project(%AppDeleted{} = event, _) do
    app = Repo.get(App, event.app_id)
    Multi.delete(multi, :app, app)
  end

  def after_update(_, _, changes) do
    PubSub.broadcast(PubSubServer, Projector.topic(), {:projected, __MODULE__, changes.app})
    :ok
  end
end
