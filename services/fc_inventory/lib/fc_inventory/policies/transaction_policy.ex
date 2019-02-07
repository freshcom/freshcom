defmodule FCInventory.TransactionPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCInventory.{CreateTransaction}

  def authorize(%CreateTransaction{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  # def authorize(%UpdateTransaction{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  # def authorize(%DeleteTransaction{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  def authorize(_, _), do: {:error, :access_denied}
end
