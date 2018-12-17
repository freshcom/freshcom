defmodule Freshcom.Account do
  use Freshcom.Projection

  schema "accounts" do
    field :prefixed_id, :string, virtual: true
    field :system_label, :string
    field :mode, :string
    field :live_account_id, UUID
    field :test_account_id, UUID
    field :default_locale, :string
    field :is_ready_for_live_transaction, :boolean, default: false

    field :handle, :string
    field :name, :string
    field :legal_name, :string
    field :website_url, :string
    field :support_email, :string
    field :tech_email, :string

    field :caption, :string
    field :description, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :owner, Freshcom.User
  end

  @type t :: Ecto.Schema.t()

  def prefixed_id(nil), do: nil
  def prefixed_id(%{id: id, mode: mode}), do: "acc-#{mode}-#{id}"

  def put_prefixed_id(nil), do: nil
  def put_prefixed_id(acc), do: %{acc | prefixed_id: prefixed_id(acc)}

  def bare_id(nil), do: nil

  def bare_id(id) do
    id
    |> String.replace_prefix("acc-test-", "")
    |> String.replace_prefix("acc-live-", "")
  end
end