defmodule Freshcom.Repo.Migrations.CreateAccount do
  use Ecto.Migration

  def change do
    create table(:accounts, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sid, :bigserial

      add :owner_id, :binary_id
      add :mode, :string
      add :is_ready_for_live_transaction, :boolean
      add :live_account_id, :binary_id
      add :test_account_id, :binary_id
      add :default_locale, :string

      add :handle, :citext
      add :name, :string
      add :legal_name, :string
      add :website_url, :string
      add :support_email, :string
      add :tech_email, :string

      add :caption, :string
      add :description, :text
      add :custom_data, :map
      add :translations, :map

      timestamps()
    end

    create index(:accounts, :sid)
    create index(:accounts, :live_account_id)
    create index(:accounts, :test_account_id)
    create index(:accounts, :owner_id)

    execute "ALTER SEQUENCE accounts_sid_seq START with 72018102 RESTART"
  end
end