defmodule Freshcom.Repo.Migrations.CreateAPIKey do
  use Ecto.Migration

  def change do
    create table(:api_keys, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, :binary_id, null: false
      add :user_id, :binary_id

      timestamps()
    end

    create index(:api_keys, [:account_id, :user_id])
    create index(:api_keys, :user_id)
  end
end
