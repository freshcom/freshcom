defmodule FCIdentity.AccountHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCIdentity.AccountPolicy

  alias FCStateStorage.GlobalStore.DefaultLocaleStore
  alias FCIdentity.TestAccountIdStore
  alias FCIdentity.{CreateAccount, UpdateAccountInfo}
  alias FCIdentity.{AccountCreated, AccountInfoUpdated}
  alias FCIdentity.Account

  def handle(%Account{id: nil} = state, %CreateAccount{} = cmd) do
    cmd
    |> authorize(state)
    ~> keep_default_locale()
    ~> keep_test_account_id()
    ~> merge_to(%AccountCreated{})
    |> unwrap_ok()
  end

  def handle(%Account{id: _}, %CreateAccount{}) do
    {:error, {:already_exist, :account}}
  end

  def handle(%Account{id: nil}, %UpdateAccountInfo{}) do
    {:error, {:not_found, :account}}
  end

  def handle(%Account{id: _} = state, %UpdateAccountInfo{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%AccountInfoUpdated{})
    |> unwrap_ok()
  end

  defp keep_default_locale(cmd) do
    DefaultLocaleStore.put(cmd.account_id, cmd.default_locale)
    cmd
  end

  defp keep_test_account_id(%{account_id: aid, mode: "live", test_account_id: taid} = cmd) do
    TestAccountIdStore.put(aid, taid)
    cmd
  end

  defp keep_test_account_id(cmd), do: cmd
end