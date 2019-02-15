defmodule FCStateStorage.MemoryAdapter do
  @behaviour FCStateStorage

  use Agent

  def start_link() do
    Agent.start_link(fn -> %{} end, name: __MODULE__)
  end

  def get(key, _ \\ []) do
    Agent.get(__MODULE__, fn(table) ->
      json = table[key]

      if json do
        Jason.decode!(json, keys: :atoms!)
      else
        nil
      end
    end)
  end

  def put(key, record, opts \\ [])

  def put(key, record, allow_overwrite: false) do
    if get(key) do
      {:error, :key_already_exist}
    else
      Agent.update(__MODULE__, fn(table) ->
        Map.put(table, key, Jason.encode!(record))
      end)

      {:ok, record}
    end
  end

  def put(key, record, _) do
    Agent.update(__MODULE__, fn(table) ->
      Map.put(table, key, Jason.encode!(record))
    end)

    {:ok, record}
  end

  def delete(key, _ \\ []) do
    Agent.update(__MODULE__, fn(table) ->
      Map.drop(table, [key])
    end)
  end

  def reset!() do
    Agent.update(__MODULE__, fn(_) ->
      %{}
    end)
  end
end
