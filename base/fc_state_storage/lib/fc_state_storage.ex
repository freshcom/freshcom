defmodule FCStateStorage do
  @store Application.get_env(:fc_state_storage, :adapter)

  @callback get(key :: String.t(), opts :: keyword) :: any
  @callback put(key :: String.t(), record :: map, opts :: keyword) :: {:ok, any} | {:error, any}

  defdelegate get(key, opts \\ []), to: @store
  defdelegate put(key, record, opts \\ []), to: @store
  defdelegate delete(key, opts \\ []), to: @store
  defdelegate reset!(), to: @store
end
