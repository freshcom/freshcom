defmodule Freshcom.IdentityPolicy do
  @moduledoc false

  @admins ["owner", "administrator"]
  @developers @admins ++ ["developer"]
  @operators @admins ++
               [
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
  def authorize(%{_client_: nil}, _), do: {:error, :access_denied}

  def authorize(%{_role_: role} = req, :list_user) when role in @admins do
    {:ok, req}
  end

  def authorize(%{requester_id: rid, identifier: %{"id" => tid}} = req, :get_user)
      when rid == tid,
      do: {:ok, req}

  def authorize(%{_role_: role} = req, :get_user) when role in @admins,
    do: {:ok, req}

  def authorize(
        %{_requester_: %{type: "standard"}, _client_: %{type: "system"}} = req,
        :list_account
      ),
      do: {:ok, req}

  def authorize(%{_role_: role} = req, :get_account) when role in @guests,
    do: {:ok, req}

  def authorize(%{_client_: %{type: "system"}} = req, :exchange_api_key),
    do: {:ok, req}

  def authorize(%{_role_: role, _client_: %{type: "system"}} = req, :get_api_key)
      when role in @developers do
    req = Map.put(req, :identifier, %{"account_id" => req.account_id, "user_id" => nil})
    {:ok, req}
  end

  def authorize(%{_role_: role, _client_: %{type: "system"}} = req, :list_app)
      when role in @developers,
      do: {:ok, req}

  def authorize(_, _), do: {:error, :access_denied}
end
