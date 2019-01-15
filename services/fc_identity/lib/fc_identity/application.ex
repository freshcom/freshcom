defmodule FCIdentity.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    FCIdentity.Supervisor.start_link(:ok)
  end
end
