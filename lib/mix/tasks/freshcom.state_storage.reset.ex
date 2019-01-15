defmodule Mix.Tasks.Freshcom.StateStorage.Reset do
  use Mix.Task

  alias FCStateStorage

  def run(_) do
    Application.ensure_all_started(:freshcom)
    FCStateStorage.reset!()
    Mix.shell().info("The StateStorage database has been reset.")
  end
end
