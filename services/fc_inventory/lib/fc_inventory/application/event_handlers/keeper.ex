defmodule FCInventory.Keeper do
  @moduledoc false

  use Commanded.Event.Handler,
    name: "event-handler:f25377d2-2659-4357-9648-1c429d65965b",
    consistency: :strong

  alias FCInventory.{LocationStore, SerialNumberStore}
  alias FCInventory.{
    LocationAdded,
    SerialNumberAdded
  }

  def handle(%LocationAdded{} = event, _) do
    data = Map.take(event, [:type, :output_strategy])
    LocationStore.put(event.account_id, event.location_id, data)

    :ok
  end

  def handle(%SerialNumberAdded{remove_at: nil, expires_at: nil}, _), do: :ok

  def handle(%SerialNumberAdded{} = event, _) do
    data = Map.take(event, [:remove_at, :expires_at])
    SerialNumberStore.put(event.account_id, event.serial_number, data)
  end

  def handle(event, _) do
    IO.inspect(event)

    :ok
  end
end
