defmodule Freshcom.Repo.Migrations.CreateStockable do
  use Ecto.Migration

  def change do
    create table(:stockables, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sid, :bigserial

      add :account_id, :binary_id
      add :avatar_id, :binary_id

      add :status, :string
      add :code, :string
      add :name, :string
      add :label, :string

      add :print_name, :string
      add :unit_of_measure, :string
      add :variable_weight, :boolean

      add :storage_type, :string
      add :storage_size, :integer
      add :stackable, :boolean

      add :specification, :text
      add :storage_description, :text

      add :caption, :string
      add :description, :text
      add :custom_data, :map
      add :translations, :map

      timestamps()
    end

    create index(:stockables, :sid)
    create index(:stockables, [:account_id, :status])
    create index(:stockables, [:account_id, :name])
    create index(:stockables, [:account_id, :label], where: "label IS NOT NULL")
  end
end
