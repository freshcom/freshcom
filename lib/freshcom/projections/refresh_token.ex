defmodule Freshcom.RefreshToken do
  use Freshcom.Projection

  schema "refresh_tokens" do
    field :account_id, UUID
    field :user_id, UUID
    field :prefixed_id, :string, virtual: true

    timestamps()
  end
end