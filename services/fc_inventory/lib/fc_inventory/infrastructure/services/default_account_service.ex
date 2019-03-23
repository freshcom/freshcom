defmodule FCInventory.DefaultAccountService do
  alias FCInventory.IAccountService

  @behaviour IAccountService

  @impl IAccountService
  def find(id) do
    {:ok, %FCInventory.Account{id: id}}
  end
end