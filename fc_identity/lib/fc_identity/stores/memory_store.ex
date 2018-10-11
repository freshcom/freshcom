defmodule FCIdentity.MemoryStore do
  @behaviour FCIdentity.SimpleStore

  use Agent

  def start_link(_) do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(key, _ \\ []) do
    Agent.get(__MODULE__, fn(table) ->
      table[key]
    end)
  end

  def put(key, record, opts \\ [])

  def put(key, record, allow_overwrite: false) do
    if get(key) do
      {:error, :key_already_exist}
    else
      Agent.update(__MODULE__, fn(table) ->
        Map.put(table, key, record)
      end)

      {:ok, record}
    end
  end

  def put(key, record, _) do
    Agent.update(__MODULE__, fn(table) ->
      Map.put(table, key, record)
    end)

    {:ok, record}
  end
end