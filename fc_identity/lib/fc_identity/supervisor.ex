defmodule FCIdentity.Supervisor do
  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      # Event Handler
      {FCIdentity.RoleKeeper, [start_from: :current]},
      {FCIdentity.UsernameKeeper, [start_from: :current]},
      {FCIdentity.TypeKeeper, [start_from: :current]},

      # Process Manager
      {FCIdentity.UserRegistration, [start_from: :current]}
      # worker(FCIdentity.RoleKeeper, [[start_from: :current]], id: :fc_identity_role_keeper)
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end