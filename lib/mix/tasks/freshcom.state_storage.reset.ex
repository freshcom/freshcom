defmodule Mix.Tasks.Freshcom.StateStorage.Reset do
  use Mix.Task

  alias FCStateStorage

  def run(_) do
    Application.ensure_all_started(:hackney)

    case Application.get_env(:fc_state_storage, :adapter) do
      FCStateStorage.MemoryAdapter ->
        Mix.shell().info("MemoryAdapter does not require reset, skipped.")

      _ ->
        FCStateStorage.reset!()
        Mix.shell().info("The state storage has been reset.")
    end
  end
end