# defmodule FCInventory.StaffService do
#   alias FCInventory.Account
#   alias FCInventory.{Manager, Associate, Worker}

#   @callback manager_from(Account.t(), String.t()) :: {:ok, Manager.t()} | {:error, :not_found}
#   @callback associate_from(Account.t(), String.t()) :: {:ok, Associate,t()} | {:error, :not_found}
#   @callback worker_from(Account.t(), String.t()) :: {:ok, Worker.t()} | {:error, :not_found}
# end