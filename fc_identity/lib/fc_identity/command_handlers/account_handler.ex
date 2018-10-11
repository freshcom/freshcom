defmodule FCIdentity.AccountHandler do
  @behaviour Commanded.Commands.Handler

  use OK.Pipe

  import FCIdentity.Support
  import FCIdentity.AccountPolicy

  alias FCIdentity.{CreateAccount, UpdateAccountInfo}
  alias FCIdentity.{AccountCreated, AccountInfoUpdated}
  alias FCIdentity.Account

  def handle(%Account{id: nil} = state, %CreateAccount{} = cmd) do
    cmd
    |> authorize(state)
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
end