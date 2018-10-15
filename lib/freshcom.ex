defmodule Freshcom do
  import FCSupport.Struct
  import FCSupport.ControlFlow, only: [tt_wrap: 1]

  use OK.Pipe

  alias Phoenix.PubSub
  alias FCIdentity.RegisterUser
  alias FCIdentity.UserRegistered
  alias Freshcom.PubSubServer
  alias Freshcom.{Router, Repo, Projector}
  alias Freshcom.{UserProjector, AccountProjector}

  def register_user(%{fields: fields}) do
    Projector.subscribe()

    result =
      %RegisterUser{}
      |> merge(fields)
      |> Router.dispatch(include_execution_result: true)
      ~> find_event(UserRegistered)
      ~>> Projector.wait_for()
      |> normalize_wait_result()
      ~> Map.get(:user)

    Projector.unsubscribe()

    result
  end

  def normalize_wait_result({:error, {:timeout, _}}), do: {:error, {:timeout, :projector_wait}}
  def normalize_wait_result(other), do: other

  def find_event(%{events: events}, module) do
    Enum.find(events, &(&1.__struct__ == module))
  end
end