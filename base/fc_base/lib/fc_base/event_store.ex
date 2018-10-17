defmodule FCBase.EventStore do
  alias EventStore.Config

  @doc """
  Clear the event store and read store databases
  """
  def reset! do
    config = Config.default_postgrex_opts(Config.parsed())
    {:ok, conn} = Postgrex.start_link(config)
    EventStore.Storage.Initializer.reset!(conn)
  end
end