defmodule Freshcom do
  import FCSupport.Struct

  use OK.Pipe

  alias FCIdentity.RegisterUser
  alias FCIdentity.UserRegistered
  alias Freshcom.{Response, Router, Projector, ProjectionWaiter}

  def register_user(%{fields: fields}) do
    Projector.subscribe()

    response =
      %RegisterUser{}
      |> merge(fields)
      |> Router.dispatch(include_execution_result: true)
      ~> find_event(UserRegistered)
      ~>> ProjectionWaiter.wait_for()
      |> normalize_wait_result()
      ~> Map.get(:user)
      |> to_response()

    Projector.unsubscribe()

    response
  end

  def normalize_wait_result({:error, {:timeout, _}}), do: {:error, {:timeout, :projector_wait}}
  def normalize_wait_result(other), do: other

  def find_event(%{events: events}, module) do
    Enum.find(events, &(&1.__struct__ == module))
  end

  defp to_response({:ok, data}) do
    {:ok, %Response{data: data}}
  end

  defp to_response({:error, {:validation_failed, errors}}) do
    {:error, %Response{errors: errors}}
  end

  defp to_response(result) do
    raise "unexpected result returned: #{result}"
  end
end