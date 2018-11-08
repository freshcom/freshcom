defmodule Freshcom.User do
  use Freshcom.Projection
  alias Freshcom.Account

  schema "users" do
    field :type, :string
    field :status, :string
    field :username, :string
    field :password_hash, :string
    field :email, :string
    field :is_term_accepted, :boolean

    field :first_name, :string
    field :last_name, :string
    field :name, :string

    field :role, :string

    field :password_reset_token, :string
    field :password_reset_token_expires_at, :naive_datetime

    field :email_verified, :boolean
    field :email_verification_token, :string
    field :email_verification_token_expires_at, :naive_datetime

    field :custom_data, :map, default: %{}
    field :translations, :map, default: %{}

    timestamps()

    belongs_to :account, Account
    belongs_to :default_account, Account
    has_many :refresh_tokens, Freshcom.RefreshToken
  end

  @type t :: Ecto.Schema.t()

  @spec is_password_valid?(__MODULE__.t(), String.t()) :: boolean
  def is_password_valid?(user, password) do
    case Comeonin.Argon2.check_pass(user, password) do
      {:ok, _} -> true
      _ -> false
    end
  end
end