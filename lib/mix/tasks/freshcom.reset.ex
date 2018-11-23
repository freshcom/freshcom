defmodule Mix.Tasks.Freshcom.Reset do
  use Mix.Task

  alias FCStateStorage

  def run(_) do
    tasks = [
      "ecto.drop",
      "ecto.create",
      "ecto.migrate",
      "event_store.drop",
      "event_store.create",
      "event_store.init",
      "freshcom.state_storage.reset"
    ]
    Enum.each(tasks, &Mix.Task.run/1)
  end
end