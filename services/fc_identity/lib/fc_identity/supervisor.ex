defmodule FCIdentity.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      # Process Manager
      {FCIdentity.DefaultAccountSetup, [start_from: :current]},
      {FCIdentity.TestAccountSync, [start_from: :current]},
      {FCIdentity.DefaultAppSetup, [start_from: :current]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end