defmodule Freshcom.RefreshToken do
  use Freshcom.Projection

  alias Freshcom.Repo
  alias Freshcom.Account

  schema "refresh_tokens" do
    field :account_id, UUID
    field :user_id, UUID
    field :prefixed_id, :string, virtual: true

    timestamps()
  end

  def prefixed_id(nil, _), do: nil
  def prefixed_id(rt, nil), do: prefixed_id(rt, Repo.get!(Account, rt.account_id))
  def prefixed_id(%{id: id, user_id: nil}, %{mode: mode}), do: "prt-#{mode}-#{id}"
  def prefixed_id(%{id: id}, %{mode: mode}), do: "urt-#{mode}-#{id}"

  def put_prefixed_id(nil, _), do: nil
  def put_prefixed_id(rt, acct), do: %{rt | prefixed_id: prefixed_id(rt, acct)}

  def bare_id(nil), do: nil

  def bare_id(id) do
    id
    |> String.replace_prefix("prt-test-", "")
    |> String.replace_prefix("prt-live-", "")
    |> String.replace_prefix("urt-test-", "")
    |> String.replace_prefix("urt-live-", "")
  end
end