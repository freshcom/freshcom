defmodule Freshcom.GoodsPolicy do
  @moduledoc false

  use Freshcom, :policy

  def authorize(%{_role_: role} = req, :list_stockable) when role in @goods_viewing_roles do
    {:ok, req}
  end

  # def authorize(req, :get_user) do
  #   cond do
  #     req.requester_id && req.requester_id == req.identifier["id"] ->
  #       {:ok, req}

  #     req._role_ in @admin_roles ->
  #       {:ok, req}

  #     true ->
  #       {:error, :access_denied}
  #   end
  # end

  # def authorize(
  #       %{_requester_: %{type: "standard"}, _client_: %{type: "system"}} = req,
  #       :list_account
  #     ),
  #     do: {:ok, req}

  # def authorize(%{_role_: role} = req, :get_account) when role in @guest_roles,
  #   do: {:ok, req}

  # def authorize(%{_client_: %{type: "system"}} = req, :exchange_api_key),
  #   do: {:ok, req}

  # def authorize(req, :get_api_key) do
  #   cond do
  #     req.requester_id && req.requester_id == req.identifier["user_id"] ->
  #       {:ok, req}

  #     req._role_ in @dev_roles ->
  #       {:ok, req}
  #   end
  # end

  # def authorize(%{_role_: role, _client_: %{type: "system"}} = req, :list_app)
  #     when role in @dev_roles,
  #     do: {:ok, req}

  def authorize(_, _), do: {:error, :access_denied}
end
