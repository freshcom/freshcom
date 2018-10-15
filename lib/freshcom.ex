defmodule Freshcom do
  import FCSupport.Struct

  use OK.Pipe

  alias FCIdentity.RegisterUser
  alias FCIdentity.UserRegistered
  alias Freshcom.{Router, Projector}

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