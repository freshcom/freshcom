defmodule Freshcom.Repo.Migrations.CreateUser do
  use Ecto.Migration

  def change do
    create table(:users, primary_key: false) do
      add :id, :binary_id, primary_key: true
      add :sid, :bigserial

      add :account_id, :binary_id
      add :default_account_id, :binary_id

      add :type, :string
      add :status, :string
      add :username, :citext
      add :password_hash, :string
      add :email, :citext
      add :is_term_accepted, :boolean

      add :first_name, :string
      add :last_name, :string
      add :name, :string

      add :role, :string

      add :password_reset_token, :string
      add :password_reset_token_expires_at, :utc_datetime
      add :password_updated_at, :utc_datetime

      add :email_verified, :boolean
      add :email_verification_token, :string
      add :email_verification_token_expires_at, :utc_datetime
      add :email_verified_at, :utc_datetime

      add :custom_data, :map
      add :translations, :map

      timestamps()
    end

    create index(:users, :sid)
    create index(:users, [:account_id])
    create index(:users, [:account_id, :username])
    create index(:users, [:username])
    create index(:users, [:account_id, :email])
    create index(:users, [:email])
    create index(:users, [:account_id, :status])
    create index(:users, [:status])

    execute "ALTER SEQUENCE users_sid_seq START with 72018102 RESTART"
  end
end
