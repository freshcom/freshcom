defmodule FCInventory.MovementPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCInventory.{CreateMovement}

  def authorize(%CreateMovement{requester_role: role} = cmd, _) when role in @goods_management_roles,
    do: {:ok, cmd}

  # def authorize(%UpdateMovement{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  # def authorize(%DeleteMovement{requester_role: role} = cmd, _) when role in @goods_management_roles,
  #   do: {:ok, cmd}

  def authorize(_, _), do: {:error, :access_denied}
end
