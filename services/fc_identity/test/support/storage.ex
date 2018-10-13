defmodule FCIdentity.Storage do
  @doc """
  Clear the event store and read store databases
  """
  def reset! do
    reset_eventstore()
  end

  defp reset_eventstore do
    config = EventStore.Config.parsed() |> EventStore.Config.default_postgrex_opts()

    {:ok, conn} = Postgrex.start_link(config)

    EventStore.Storage.Initializer.reset!(conn)
  end
end