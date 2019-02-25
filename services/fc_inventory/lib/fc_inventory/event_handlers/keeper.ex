defmodule FCInventory.Keeper do
  @moduledoc false

  use Commanded.Event.Handler,
    name: "event-handler:f25377d2-2659-4357-9648-1c429d65965b",
    consistency: :strong

  def handle(event, _) do
    # IO.inspect event

    :ok
  end
end
