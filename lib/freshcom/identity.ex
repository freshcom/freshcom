defmodule Freshcom.Identity do
  import Freshcom.Context
  import FCSupport.Struct

  use OK.Pipe

  alias FCIdentity.RegisterUser
  alias FCIdentity.UserRegistered
  alias Freshcom.{Router, Projector, ProjectionWaiter}

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
end