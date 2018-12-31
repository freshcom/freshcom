defmodule Freshcom.APIKeyProjector do
  @moduledoc false

  use Freshcom.Projector
  use Commanded.Projections.Ecto, name: "projector:431b1a65-b05b-4eb7-908c-b3accfd0b017"

  import UUID

  alias Freshcom.Repo
  alias Freshcom.{Account, APIKey}
  alias FCIdentity.{
    AccountCreated,
    UserAdded
  }

  project(%AccountCreated{} = event, _metadata) do
    prt = %APIKey{id: uuid4(), account_id: event.account_id}
    urt = %APIKey{id: uuid4(), user_id: event.owner_id, account_id: event.account_id}

    multi
    |> Multi.insert(:prt, prt)
    |> Multi.insert(:urt, urt)
  end

  project(%UserAdded{} = event, _metadata) do
    target_urt = %APIKey{id: uuid4(), user_id: event.user_id, account_id: event.account_id}
    multi = Multi.insert(multi, :target_urt, target_urt)

    %{test_account_id: test_account_id} = Repo.get!(Account, event.account_id)
    if test_account_id do
      test_urt = %APIKey{id: uuid4(), user_id: event.user_id, account_id: test_account_id}
      Multi.insert(multi, :test_urt, test_urt)
    else
      multi
    end
  end
end