defmodule FCInventory.Keeper do
  @moduledoc false

  use Commanded.Event.Handler,
    name: "event-handler:5f0f26d9-d22e-4930-b69c-0f238ab830c1",
    consistency: :strong

  alias Decimal, as: D
  alias FCInventory.BatchAdded
  alias FCInventory.AvailableBatchStore

  def handle(%BatchAdded{} = event, _) do
    batch =
      event
      |> Map.take([:quantity_on_hand, :expires_at])
      |> Map.put(:id, event.batch_id)
      |> Map.put(:quantity_reserved, D.new(0))

    AvailableBatchStore.put(event.account_id, event.stockable_id, batch)

    :ok
  end
end
