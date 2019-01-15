defmodule Mix.Tasks.Freshcom.Reset do
  use Mix.Task

  alias FCStateStorage

  def run(_) do
    tasks = [
      {"ecto.drop", ["-r", "Freshcom.Repo"]},
      {"ecto.create", ["-r", "Freshcom.Repo"]},
      {"ecto.migrate", ["-r", "Freshcom.Repo"]},
      {"event_store.drop", []},
      {"event_store.create", []},
      {"event_store.init", []},
      {"freshcom.state_storage.reset", []}
    ]

    Enum.each(tasks, fn {cmd, opts} -> Mix.Task.run(cmd, opts) end)
  end
end
