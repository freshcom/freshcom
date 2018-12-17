defmodule FCIdentity.DefaultAccountSetup do
  @moduledoc false
  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:b4e57a07-3136-4a9f-8f8b-cbae5f86ed4d",
    router: FCIdentity.Router

  alias FCIdentity.{UserRegistered, AccountCreated}
  alias FCIdentity.CreateAccount

  defstruct []

  def interested?(%UserRegistered{user_id: user_id}), do: {:start, user_id}
  def interested?(%AccountCreated{owner_id: owner_id, mode: "live"}), do: {:stop, owner_id}
  def interested?(_), do: false

  def handle(_, %UserRegistered{} = event) do
    %CreateAccount{
      requester_role: "system",
      account_id: event.default_account_id,
      system_label: "default",
      owner_id: event.user_id,
      mode: "live",
      name: event.account_name,
      default_locale: event.default_locale
    }
  end
end