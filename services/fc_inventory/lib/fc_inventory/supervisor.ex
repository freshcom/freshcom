defmodule FCInventory.Supervisor do
  @moduledoc false

  use Supervisor

  def start_link(_) do
    Supervisor.start_link(__MODULE__, [], name: __MODULE__)
  end

  def init(_) do
    children = [
      {FCInventory.Keeper, [start_from: :current]},
      # Process Manager
      {FCInventory.StockReservation, [start_from: :current]},
      {FCInventory.StockReservationDecrease, [start_from: :current]}
    ]

    Supervisor.init(children, strategy: :one_for_one)
  end
end
