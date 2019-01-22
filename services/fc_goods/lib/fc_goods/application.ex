defmodule FCGoods.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    FCGoods.Supervisor.start_link(:ok)
  end
end
