defmodule Freshcom.RefreshToken do
  use Freshcom.Projection

  schema "refresh_tokens" do
    field :account_id, UUID
    field :user_id, UUID

    timestamps()
  end

  def prefixed_id(nil, _), do: nil
  def prefixed_id(%{id: id, user_id: nil}, %{mode: mode}), do: "prt-#{mode}-#{id}"
  def prefixed_id(%{id: id}, %{mode: mode}), do: "urt-#{mode}-#{id}"

  def unprefix_id(id) do
    id
    |> String.replace_prefix("prt-test-", "")
    |> String.replace_prefix("prt-live-", "")
    |> String.replace_prefix("urt-test-", "")
    |> String.replace_prefix("urt-live-", "")
  end
end