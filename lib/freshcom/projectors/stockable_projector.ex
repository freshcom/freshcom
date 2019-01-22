defmodule Freshcom.StockableProjector do
  @moduledoc false

  use Freshcom.Projector
  use Commanded.Projections.Ecto, name: "projector:ade1e158-ccbe-4263-8195-649c4f0dfdf8"

  alias Freshcom.Stockable

  alias FCGoods.{
    StockableAdded,
    StockableUpdated
  }

  project(%StockableAdded{} = event, _metadata) do
    stockable = Struct.merge(%Stockable{id: event.stockable_id}, event)
    Multi.insert(multi, :stockable, stockable)
  end

  project(%StockableUpdated{} = event, _) do
    changeset =
      Stockable
      |> Repo.get(event.stockable_id)
      |> Projection.changeset(event)

    Multi.update(multi, :stockable, changeset)
  end

  # project(%StockableDeleted{} = event, _) do
  #   app = Repo.get(Stockable, event.app_id)
  #   Multi.delete(multi, :app, app)
  # end

  def after_update(_, _, changes) do
    PubSub.broadcast(PubSubServer, Projector.topic(), {:projected, __MODULE__, changes.stockable})
    :ok
  end
end
