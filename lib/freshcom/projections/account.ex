defmodule Freshcom.Account do
  use Freshcom, :projection

  schema "accounts" do
    field :owner_id, UUID
    field :mode, :string
    field :default_locale, :string

    field :name, :string
    field :legal_name, :string
    field :website_url, :string
    field :support_email, :string
    field :tech_email, :string

    field :caption, :string
    field :description, :string
    field :custom_data, :map
    field :translations, :map

    timestamps()

    belongs_to :live_account, __MODULE__
    belongs_to :test_account, __MODULE__
  end
end