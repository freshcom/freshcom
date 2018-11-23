defmodule Mix.Tasks.Freshcom.StateStorage.Reset do
  use Mix.Task

  alias FCStateStorage

  def run(_) do
    Application.ensure_all_started(:hackney)
    FCStateStorage.reset!()
  end
end