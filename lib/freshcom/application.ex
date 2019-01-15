defmodule Freshcom.Application do
  @moduledoc false

  use Application

  def start(_type, _args) do
    Freshcom.Supervisor.start_link()
  end
end
