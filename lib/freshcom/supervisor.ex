defmodule Freshcom.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link do
    Supervisor.start_link(__MODULE__, :ok, name: __MODULE__)
  end

  def init(:ok) do
    children = [
      Freshcom.Repo,
      {Freshcom.AccountProjector, []},
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end