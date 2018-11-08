defmodule Freshcom.Account do
  use Freshcom.Projection

  schema "accounts" do
    field :mode, :string
    field :live_account_id, UUID
    field :test_account_id, UUID
    field :default_locale, :string

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
end