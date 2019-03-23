defmodule FCInventory.IStaffService do
  alias FCInventory.Account
  alias FCInventory.Staff

  @callback find(Account.t(), String.t()) :: {:ok, Staff.t()} | {:error, {:not_found, :staff}}
end

defmodule FCInventory.StaffService do
  alias FCInventory.{IStaffService, DefaultStaffService, System}

  @behaviour IStaffService
  @service Application.get_env(:fc_inventory, StaffService) || DefaultStaffService

  @impl IStaffService
  def find(account, "system"), do: {:ok, %System{account_id: account.id, id: "system"}}
  defdelegate find(account, staff_id), to: @service
end
