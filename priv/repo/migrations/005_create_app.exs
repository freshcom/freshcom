defmodule Freshcom.Repo.Migrations.CreateApp do
  use Ecto.Migration

  def change do
    create table(:apps, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :account_id, :binary_id
      add :type, :string
      add :status, :string
      add :name, :string

      timestamps()
    end

    create index(:apps, :account_id)
  end
end
