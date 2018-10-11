defmodule FCIdentity.Application do
  use Application

  def start(_type, _args) do
    FCIdentity.Supervisor.start_link()
  end
end