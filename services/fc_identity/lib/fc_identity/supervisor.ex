defmodule FCIdentity.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      # Event Handler
      {FCIdentity.RoleKeeper, [start_from: :current]},
      {FCIdentity.UsernameKeeper, [start_from: :current]},
      {FCIdentity.TypeKeeper, [start_from: :current]},
      {FCIdentity.TestAccountIdKeeper, [start_from: :current]},

      # Process Manager
      {FCIdentity.DefaultAccountSetup, [start_from: :current]},
      {FCIdentity.TestAccountSetup, [start_from: :current]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end