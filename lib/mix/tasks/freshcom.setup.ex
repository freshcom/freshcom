defmodule Mix.Tasks.Freshcom.Setup do
  use Mix.Task

  alias FCStateStorage

  def run(_) do
    tasks = [
      {"ecto.create", ["-r", "Freshcom.Repo"]},
      {"ecto.migrate", ["-r", "Freshcom.Repo"]},
      {"event_store.create", []},
      {"event_store.init", []}
    ]

    Enum.each(tasks, fn {cmd, opts} -> Mix.Task.run(cmd, opts) end)
  end
end
