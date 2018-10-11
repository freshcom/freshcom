defmodule FCIdentity.UserRegistration do
  use TypedStruct
  use Commanded.ProcessManagers.ProcessManager,
    name: "1c03fc1e-af6b-42f4-96f6-2685114677e9",
    router: FCIdentity.Router

  import FCIdentity.Support
  import UUID

  alias FCIdentity.{UserRegistrationRequested, UserAdded, AccountCreated, UserRegistered}
  alias FCIdentity.{AddUser, CreateAccount, FinishUserRegistration}

  typedstruct do
    field :user_id, String.t()
    field :live_account_id, String.t()
    field :test_account_id, String.t()
    field :is_term_accepted, boolean, default: false
    field :is_user_added, boolean, default: false
    field :is_live_account_created, boolean, default: false
    field :is_test_account_created, boolean, default: false
  end

  def interested?(%UserRegistrationRequested{user_id: user_id}), do: {:start, user_id}
  def interested?(%UserAdded{user_id: user_id}), do: {:continue, user_id}
  def interested?(%AccountCreated{owner_id: owner_id}), do: {:continue, owner_id}
  def interested?(%UserRegistered{user_id: user_id}), do: {:stop, user_id}
  def interested?(_), do: false

  def handle(_, %UserRegistrationRequested{} = event) do
    live_account_id = uuid4()
    test_account_id = uuid4()

    add_user = %AddUser{
      requester_role: "system",
      _type_: "standard",

      account_id: live_account_id,
      status: "pending",
      role: "owner"
    }
    add_user = struct_merge(add_user, event)

    create_live_account = %CreateAccount{
      requester_role: "system",
      account_id: live_account_id,
      owner_id: event.user_id,
      mode: "live",
      test_account_id: test_account_id,
      name: event.account_name,
      default_locale: event.default_locale
    }

    create_test_account = %CreateAccount{
      requester_role: "system",
      account_id: test_account_id,
      owner_id: event.user_id,
      mode: "test",
      live_account_id: live_account_id,
      name: event.account_name,
      default_locale: event.default_locale
    }

    [create_live_account, create_test_account, add_user]
  end

  def handle(%{is_user_added: true, is_live_account_created: true} = state, %AccountCreated{mode: "test"}) do
    %FinishUserRegistration{user_id: state.user_id, is_term_accepted: state.is_term_accepted}
  end

  def handle(%{is_user_added: true, is_test_account_created: true} = state, %AccountCreated{mode: "live"}) do
    %FinishUserRegistration{user_id: state.user_id, is_term_accepted: state.is_term_accepted}
  end

  def handle(%{is_live_account_created: true, is_test_account_created: true} = state, %UserAdded{} = event) do
    %FinishUserRegistration{user_id: event.user_id, is_term_accepted: state.is_term_accepted}
  end

  def apply(state, %UserRegistrationRequested{} = event) do
    %{state | is_term_accepted: event.is_term_accepted}
  end

  def apply(%{is_user_added: false} = state, %UserAdded{} = event) do
    %{state | is_user_added: true, user_id: event.user_id}
  end

  def apply(%{is_live_account_created: false} = state, %AccountCreated{mode: "live"} = event) do
    %{state | is_live_account_created: true, live_account_id: event.account_id}
  end

  def apply(%{is_test_account_created: false} = state, %AccountCreated{mode: "test"} = event) do
    %{state | is_test_account_created: true, test_account_id: event.account_id}
  end
end