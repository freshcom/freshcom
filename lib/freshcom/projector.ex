defmodule Freshcom.Projector do

  alias FCIdentity.UserRegistered
  alias Phoenix.PubSub
  alias Freshcom.PubSubServer
  alias Freshcom.{UserProjector, AccountProjector}

  defmacro __using__(_) do
    quote do
      alias Ecto.{Changeset, Multi}
      alias Phoenix.PubSub
      alias Freshcom.{Projector, PubSubServer}

      defdelegate struct_merge(dest, stc), to: FCSupport.Struct, as: :merge
    end
  end

  def topic do
    "projectors"
  end

  def subscribe() do
    PubSub.subscribe(PubSubServer, topic())
  end

  def unsubscribe() do
    PubSub.unsubscribe(PubSubServer, topic())
  end

  def wait_for(%UserRegistered{user_id: user_id}) do
    wait([
      {:user, UserProjector, &(&1.id == user_id)},
      {:live_account, AccountProjector, &(&1.owner_id == user_id && &1.mode == "live")},
      {:test_account, AccountProjector, &(&1.owner_id == user_id && &1.mode == "test")}
    ])
  end

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
      Enum.find(conditions, fn({_, projector, tester}) ->
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