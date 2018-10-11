defmodule FCIdentity.SimpleStore do
  @store Application.get_env(:fc_identity, __MODULE__)

  @callback get(key :: String.t(), opts :: keyword) :: any
  @callback put(key :: String.t(), record :: map, opts :: keyword) :: {:ok, any} | {:error, any}

  defdelegate get(key, opts \\ []), to: @store
  defdelegate put(key, record, opts \\ []), to: @store
end