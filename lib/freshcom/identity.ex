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
  alias Freshcom.{Router, Projector, ProjectionWaiter}

  def register_user(%{fields: fields}) do
    cmd = %RegisterUser{}
    fields = atomize_keys(fields, Map.keys(cmd))

    Projector.subscribe()

    response =
      cmd
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

  def update_user_info(%Request{} = req) do
    cmd = %UpdateUserInfo{}
    identifiers = atomize_keys(req.identifiers, ["id"])
    fields = atomize_keys(req.fields, Map.keys(cmd))

    cmd
    |> merge(fields)
    |> put_requester(req)
    |> Map.put(:locale, req.locale)
    |> Map.put(:effective_keys, Map.keys(fields))
    |> Map.put(:user_id, identifiers[:id])
    |> Router.dispatch(include_execution_result: true)
    ~> Map.get(:user)
    |> to_response()
  end
end