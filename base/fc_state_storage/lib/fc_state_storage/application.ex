defmodule FCStateStorage.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    FCStateStorage.Supervisor.start_link(:ok)
  end
end