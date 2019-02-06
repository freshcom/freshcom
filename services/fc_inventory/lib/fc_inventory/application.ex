defmodule FCInventory.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    FCInventory.Supervisor.start_link(:ok)
  end
end
