defmodule FCStateStorage.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    adapter = Application.get_env(:fc_state_storage, :adapter)
    children = [
      %{
        id: adapter,
        start: {adapter, :start_link, []}
      }
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end