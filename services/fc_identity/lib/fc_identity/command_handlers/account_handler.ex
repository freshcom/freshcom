defmodule FCIdentity.AccountHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCIdentity.AccountPolicy

  alias FCStateStorage.GlobalStore.{DefaultLocaleStore, UserRoleStore}
  alias FCIdentity.{TestAccountIdStore, AccountAliasStore}
  alias FCIdentity.{CreateAccount, UpdateAccountInfo}
  alias FCIdentity.{AccountCreated, AccountInfoUpdated}
  alias FCIdentity.Account

  def handle(%Account{id: nil} = state, %CreateAccount{} = cmd) do
    cmd
    |> authorize(state)
    ~> keep_default_locale()
    ~> keep_owner_role()
    ~> keep_test_account_id()
    ~> keep_account_alias()
    ~> merge_to(%AccountCreated{alias: cmd.account_id})
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
    ~> keep_account_alias(state)
    ~> merge_to(%AccountInfoUpdated{})
    |> unwrap_ok()
  end

  defp keep_default_locale(%CreateAccount{} = cmd) do
    DefaultLocaleStore.put(cmd.account_id, cmd.default_locale)
    cmd
  end

  defp keep_owner_role(%CreateAccount{account_id: account_id, owner_id: owner_id} = cmd) do
    UserRoleStore.put(owner_id, account_id, "owner")
    cmd
  end

  defp keep_test_account_id(%CreateAccount{account_id: aid, mode: "live", test_account_id: taid} = cmd) do
    TestAccountIdStore.put(taid, aid)
    cmd
  end

  defp keep_test_account_id(cmd), do: cmd

  defp keep_account_alias(%CreateAccount{account_id: aid} = cmd) do
    AccountAliasStore.put(aid, aid)
    cmd
  end

  defp keep_account_alias(%UpdateAccountInfo{account_id: aid} = cmd, state) do
    if Enum.member?(cmd.effective_keys, "alias") && cmd.alias != state.alias do
      AccountAliasStore.delete(state.alias)
      AccountAliasStore.put(cmd.alias, cmd.account_id)
    end

    cmd
  end
end