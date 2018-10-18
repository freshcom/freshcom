defmodule Freshcom.Identity do
  import Freshcom.Context
  import FCSupport.Struct

  use OK.Pipe

  alias Freshcom.Request
  alias FCIdentity.{
    RegisterUser,
    UpdateUserInfo,
    AddUser
  }
  alias FCIdentity.{
    UserRegistered,
    UserAdded,
    UserInfoUpdated
  }
  alias Freshcom.Projector
  alias Freshcom.{UserProjector, AccountProjector}

  def register_user(%Request{} = req) do
    req
    |> to_command(%RegisterUser{})
    |> dispatch_and_wait(UserRegistered)
    ~> Map.get(:user)
    |> to_response()
  end

  def update_user_info(%Request{} = req) do
    identifiers = atomize_keys(req.identifiers, ["id"])

    req
    |> to_command(%UpdateUserInfo{})
    |> Map.put(:user_id, identifiers[:id])
    |> dispatch_and_wait(UserInfoUpdated)
    ~> Map.get(:user)
    |> to_response()
  end

  def add_user(%Request{} = req) do
    req
    |> to_command(%AddUser{})
    |> dispatch_and_wait(UserAdded)
    ~> Map.get(:user)
    |> to_response()
  end

  defp dispatch_and_wait(cmd, event) do
    dispatch_and_wait(cmd, event, &wait/1)
  end

  defp wait(%UserRegistered{user_id: user_id}) do
    Projector.wait([
      {:user, UserProjector, &(&1.id == user_id)},
      {:live_account, AccountProjector, &(&1.owner_id == user_id && &1.mode == "live")},
      {:test_account, AccountProjector, &(&1.owner_id == user_id && &1.mode == "test")}
    ])
  end

  defp wait(%event{user_id: user_id}) when event in [UserInfoUpdated, UserAdded] do
    Projector.wait([
      {:user, UserProjector, &(&1.id == user_id)}
    ])
  end
end