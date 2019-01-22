defmodule Freshcom.Repo.Migrations.CreateStockable do
  use Ecto.Migration

  def change do
    create table(:stockables, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sid, :bigserial

      add :account_id, :binary_id
      add :avatar_id, :binary_id

      add :status, :string
      add :number, :string
      add :barcode, :string

      add :name, :string
      add :label, :string
      add :print_name, :string
      add :unit_of_measure, :string
      add :specification, :text

      add :variable_weight, :boolean
      add :weight, :decimal
      add :weight_unit, :string

      add :storage_type, :string
      add :storage_size, :integer
      add :storage_description, :string
      add :stackable, :boolean

      add :width, :decimal
      add :length, :decimal
      add :height, :decimal
      add :dimension_unit, :string

      add :caption, :string
      add :description, :text
      add :custom_data, :map
      add :translations, :map

      timestamps()
    end

    create index(:stockables, :sid)
    create index(:stockables, [:account_id, :status])
    create index(:stockables, [:account_id, :number], where: "number IS NOT NULL")
    create index(:stockables, [:account_id, :barcode], where: "barcode IS NOT NULL")
    create index(:stockables, [:account_id, :name])
    create index(:stockables, [:account_id, :print_name])
    create index(:stockables, [:account_id, :label], where: "label IS NOT NULL")
  end
end
