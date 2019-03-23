defmodule FCInventory.IAccountService do
  alias FCInventory.Account

  @callback find(String.t()) :: {:ok, Account.t()} | {:error, {:not_found, :account}}
end

defmodule FCInventory.AccountService do
  alias FCInventory.{IAccountService, DefaultAccountService}

  @behaviour IAccountService
  @service Application.get_env(:fc_inventory, AccountService) || DefaultAccountService

  @impl IAccountService
  defdelegate find(id), to: @service
end
