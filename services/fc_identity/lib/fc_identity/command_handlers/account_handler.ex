defmodule FCIdentity.AccountHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import UUID
  import FCIdentity.AccountPolicy

  alias FCIdentity.AccountHandleStore
  alias FCIdentity.{CreateAccount, UpdateAccountInfo, AccountClosed}
  alias FCIdentity.{AccountCreated, AccountInfoUpdated, CloseAccount}
  alias FCIdentity.Account

  def handle(%Account{id: nil} = state, %CreateAccount{} = cmd) do
    cmd
    |> authorize(state)
    ~> generate_test_account_id()
    ~> keep_account_handle()
    ~> merge_to(%AccountCreated{handle: cmd.account_id})
    |> unwrap_ok()
  end

  def handle(%Account{id: _}, %CreateAccount{}), do: {:error, {:already_exist, :account}}
  def handle(%Account{status: "closed"}, %CreateAccount{}), do: {:error, {:already_closed, :account}}
  def handle(%Account{id: nil}, _), do: {:error, {:not_found, :account}}

  def handle(%Account{id: _} = state, %UpdateAccountInfo{} = cmd) do
    cmd
    |> authorize(state)
    ~> keep_account_handle(state)
    ~> merge_to(%AccountInfoUpdated{})
    |> unwrap_ok()
  end

  def handle(%Account{system_label: "default"}, %CloseAccount{}) do
    {:error, {:unclosable, :account}}
  end

  def handle(%Account{} = state, %CloseAccount{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%AccountClosed{
        owner_id: state.owner_id,
        mode: state.mode,
        test_account_id: state.test_account_id,
        handle: state.handle
      })
    |> unwrap_ok()
  end

  defp keep_account_handle(%CreateAccount{account_id: aid} = cmd) do
    AccountHandleStore.put(aid, aid)
    cmd
  end

  defp keep_account_handle(%UpdateAccountInfo{} = cmd, state) do
    if Enum.member?(cmd.effective_keys, "handle") && cmd.handle != state.handle do
      AccountHandleStore.delete(state.handle)
      AccountHandleStore.put(cmd.handle, cmd.account_id)
    end

    cmd
  end

  defp generate_test_account_id(%CreateAccount{mode: "live"} = event) do
    %{event | test_account_id: uuid4()}
  end

  defp generate_test_account_id(event), do: event
end