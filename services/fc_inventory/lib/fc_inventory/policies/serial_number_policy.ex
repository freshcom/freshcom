defmodule FCInventory.SerialNumberPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCInventory.{
    AddSerialNumber
  }

  def authorize(%AddSerialNumber{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  def authorize(_, _), do: {:error, :access_denied}
end
