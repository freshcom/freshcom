defmodule Freshcom.Repo.Migrations.CreateRefreshToken do
  use Ecto.Migration

  def change do
    create table(:refresh_tokens, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, :binary_id, null: false
      add :user_id, :binary_id

      timestamps()
    end

    create index(:refresh_tokens, [:account_id, :user_id])
    create index(:refresh_tokens, :user_id)
  end
end
