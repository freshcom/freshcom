ExUnit.start()

FCStateStorage.MemoryAdapter.start_link(:ok)
Ecto.Adapters.SQL.Sandbox.mode(Freshcom.Repo, :manual)