defmodule Freshcom.Projector do
  alias Phoenix.PubSub
  alias Freshcom.PubSubServer

  defmacro __using__(_) do
    quote do
      alias Ecto.{Changeset, Multi}
      alias Phoenix.PubSub
      alias Freshcom.{Projector, Projection, PubSubServer}
      alias FCSupport.Struct
    end
  end

  @doc """
  The topic used to subscribe projector updates.
  """
  def topic do
    "projectors"
  end

  @doc """
  Subscribe the current process to updates of all projectors.
  """
  def subscribe() do
    PubSub.subscribe(PubSubServer, topic())
  end

  @doc """
  Unsubscribe the current process from all projectors update.
  """
  def unsubscribe() do
    PubSub.unsubscribe(PubSubServer, topic())
  end

  @doc """
  Wait for projections of some projectors to satisfied the provided testing functions.

  *Note: you must call `subscribe/0` to subscribe for projector updates
  before calling this function otherwise this function will always timeout.*

  This function will block until all testing functions are satisfied, in which case
  it will return a map containing all the projections that satisfied the testing function.

  If the testing function is not satisfied within the timeout period this function will
  return `{:error, {:timeout, result_so_far}}`.
  """
  @spec wait([{name :: atom, projector_module :: atom, wait :: function}], keyword) ::
          {:ok, map} | {:error, {:timeout, map}}
  def wait(conditions, opts \\ []) do
    wait(conditions, opts, %{})
  end

  defp wait([], _, acc_result), do: {:ok, acc_result}

  defp wait(conditions, opts, acc_result) do
    timeout = opts[:timeout] || 5_000

    receive do
      {:projected, projector, projection} ->
        {result, leftovers} = fulfill_condition(conditions, projector, projection)
        wait(leftovers, opts, Map.merge(acc_result, result || %{}))
    after
      timeout -> {:error, {:timeout, acc_result}}
    end
  end

  defp fulfill_condition(conditions, target_projector, projection) do
    matching_condition =
      Enum.find(conditions, fn {_, projector, tester} ->
        projector == target_projector && tester.(projection)
      end)

    case matching_condition do
      nil ->
        {nil, conditions}

      {name, _, _} ->
        result = Map.put(%{}, name, projection)
        leftovers = conditions -- [matching_condition]
        {result, leftovers}
    end
  end
end
