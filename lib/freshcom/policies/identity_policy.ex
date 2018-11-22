defmodule Freshcom.IdentityPolicy do

  @admins [
    "owner",
    "administrator"
  ]

  @operators @admins ++ [
    "developer",
    "manager",
    "marketing_specialist",
    "goods_specialist",
    "support_specialist",
    "read_only"
  ]

  @guests @operators ++ @admins ++ ["guest"]

  def authorize(%{_role_: "sysdev"} = req, _), do: {:ok, req}
  def authorize(%{_role_: "system"} = req, _), do: {:ok, req}
  def authorize(%{_role_: "appdev"} = req, _), do: {:ok, req}

  def authorize(%{_role_: role} = req, :list_user) when role in @admins,
    do: {:ok, req}

  def authorize(%{requester_id: rid, identifiers: %{"id" => tid}} = req, :get_user) when rid == tid,
    do: {:ok, req}

  def authorize(%{_role_: role} = req, :get_user) when role in @admins,
    do: {:ok, req}

  def authorize(%{_role_: role} = req, :get_account) when role in @guests,
    do: {:ok, req}

  def authorize(req, :exchange_refresh_token),
    do: {:ok, req}

  def authorize(_, _), do: {:error, :access_denied}
end