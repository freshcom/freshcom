defmodule FCStateStorage.RedisAdapter do
  @behaviour FCStateStorage
  @redis_opts Application.get_env(:fc_state_storage, :redis)

  def start_link() do
    Redix.start_link(@redis_opts, name: __MODULE__)
  end

  def get(key, _ \\ []) do
    {:ok, json} = Redix.command(__MODULE__, ["GET", key])

    if json do
      Jason.decode!(json, keys: :atoms!)
    else
      nil
    end
  end

  def put(key, record, opts \\ [])

  def put(key, record, allow_overwrite: false) do
    json = Jason.encode!(record)
    {:ok, status} = Redix.command(__MODULE__, ["SETNX", key, json])

    if status == 0 do
      {:error, :key_already_exist}
    else
      {:ok, record}
    end
  end

  def put(key, record, _) do
    json = Jason.encode!(record)
    {:ok, _} = Redix.command(__MODULE__, ["SET", key, json])

    {:ok, record}
  end

  def delete(key, _ \\ []) do
    {:ok, _} = Redix.command(__MODULE__, ["DEL", key])

    :ok
  end

  def reset!() do
    {:ok, _} = Redix.command(__MODULE__, ["FLUSHDB"])
    :ok
  end
end
