defmodule Freshcom.App do
  use Freshcom.Projection

  alias Freshcom.Repo
  alias Freshcom.Account

  schema "apps" do
    field :status, :string
    field :type, :string
    field :name, :string
    field :prefixed_id, :string, virtual: true

    timestamps()

    belongs_to :account, Account
  end

  def prefixed_id(nil), do: nil
  def prefixed_id(%{id: id, type: "system"}), do: "app-#{id}"

  def prefixed_id(%{id: id} = app) do
    %{account: account} = Repo.preload(app, :account)
    "app-#{account.mode}-#{id}"
  end

  def put_prefixed_id(nil), do: nil
  def put_prefixed_id(app) when is_map(app), do: %{app | prefixed_id: prefixed_id(app)}

  def put_prefixed_id(apps) when is_list(apps) do
    Enum.map(apps, &put_prefixed_id/1)
  end

  def put_account(app, account) when is_map(app), do: %{app | account: account}

  def put_account(apps, account) when is_list(apps) do
    Enum.map(apps, &put_account(&1, account))
  end

  def bare_id(nil), do: nil

  def bare_id(id) do
    id
    |> String.replace_prefix("app-test-", "")
    |> String.replace_prefix("app-live-", "")
    |> String.replace_prefix("app-", "")
  end
end
