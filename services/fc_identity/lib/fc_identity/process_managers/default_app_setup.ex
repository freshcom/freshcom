defmodule FCIdentity.DefaultAppSetup do
  @moduledoc false
  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:2701fc26-46e3-4017-b8ce-9fd04c138de8",
    router: FCIdentity.Router

  alias FCIdentity.{AccountCreated, AppAdded}
  alias FCIdentity.AddApp

  defstruct []

  def interested?(%AccountCreated{account_id: account_id}), do: {:start, account_id}
  def interested?(%AppAdded{account_id: account_id}), do: {:stop, account_id}
  def interested?(_), do: false

  def handle(_, %AccountCreated{account_id: account_id} = event) do
    %AddApp{
      requester_role: "system",
      account_id: account_id,
      type: "standard",
      name: "Default"
    }
  end
end