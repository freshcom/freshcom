defmodule FCIdentity.DefaultAccountSync do
  @moduledoc false
  use Commanded.ProcessManagers.ProcessManager,
    name: "process-manager:076e9b6e-a4f4-461b-b876-963bcf7b92bb",
    router: FCIdentity.Router

  alias FCIdentity.{DefaultAccountChanged, AccountSystemLabelChanged}
  alias FCIdentity.ChangeAccountSystemLabel

  defstruct []

  def interested?(%DefaultAccountChanged{default_account_id: daid}), do: {:start, daid}
  def interested?(%AccountSystemLabelChanged{account_id: account_id}), do: {:stop, account_id}

  def interested?(_), do: false

  def handle(_, %DefaultAccountChanged{default_account_id: daid, original_default_account_id: odaid}) do
    [
      %ChangeAccountSystemLabel{
        requester_role: "system",
        account_id: daid,
        system_label: "default"
      },
      %ChangeAccountSystemLabel{
        requester_role: "system",
        account_id: odaid,
        system_label: nil
      }
    ]
  end
end