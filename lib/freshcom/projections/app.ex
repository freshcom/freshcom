defmodule Freshcom.App do
  use Freshcom.Projection

  alias Freshcom.Repo
  alias Freshcom.Account

  schema "apps" do
    field :account_id, UUID
    field :status, :string
    field :type, :string
    field :name, :string
    field :prefixed_id, :string, virtual: true

    timestamps()
  end

  def prefixed_id(nil, _), do: nil
  def prefixed_id(app, nil), do: prefixed_id(app, Repo.get!(Account, app.account_id))
  def prefixed_id(%{id: id, type: "standard"}, %{mode: mode}), do: "app-#{mode}-#{id}"
  def prefixed_id(%{id: id, type: "system"}), do: "app-#{id}"

  def put_prefixed_id(nil, _), do: nil
  def put_prefixed_id(app, acct), do: %{app | prefixed_id: prefixed_id(app, acct)}

  def bare_id(nil), do: nil

  def bare_id(id) do
    id
    |> String.replace_prefix("app-test-", "")
    |> String.replace_prefix("app-live-", "")
    |> String.replace_prefix("app-", "")
  end
end