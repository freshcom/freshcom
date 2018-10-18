defmodule Freshcom.Identity do
  import Freshcom.Context
  import FCSupport.Struct

  use OK.Pipe

  alias Freshcom.Request
  alias FCIdentity.{
    RegisterUser,
    UpdateUserInfo
  }
  alias FCIdentity.UserRegistered
  alias Freshcom.{Projector, ProjectionWaiter}

  def register_user(%Request{} = req) do
    Projector.subscribe()

    response =
      req
      |> to_command(%RegisterUser{})
      |> dispatch()
      ~> find_event(UserRegistered)
      ~>> ProjectionWaiter.wait_for()
      |> normalize_wait_result()
      ~> Map.get(:user)
      |> to_response()

    Projector.unsubscribe()

    response
  end

  def update_user_info(%Request{} = req) do
    identifiers = atomize_keys(req.identifiers, ["id"])

    req
    |> to_command(%UpdateUserInfo{})
    |> Map.put(:user_id, identifiers[:id])
    |> dispatch()
    ~> Map.get(:user)
    |> to_response()
  end
end