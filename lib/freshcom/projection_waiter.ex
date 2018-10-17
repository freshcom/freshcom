defmodule Freshcom.ProjectionWaiter do
  import Freshcom.Projector, only: [wait: 1]

  alias FCIdentity.UserRegistered
  alias Freshcom.{UserProjector, AccountProjector}

  def wait_for(%UserRegistered{user_id: user_id}) do
    wait([
      {:user, UserProjector, &(&1.id == user_id)},
      {:live_account, AccountProjector, &(&1.owner_id == user_id && &1.mode == "live")},
      {:test_account, AccountProjector, &(&1.owner_id == user_id && &1.mode == "test")}
    ])
  end
end