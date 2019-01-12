defmodule Freshcom.Stockable do
  use Freshcom.Projection

  schema "stockables" do
    field :status, :string
    field :name, :string

    field :caption, :string
    field :description, :string

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
  end

  @type t :: Ecto.Schema.t()
end