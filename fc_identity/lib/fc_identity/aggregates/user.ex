defmodule FCIdentity.User do
  @moduledoc false

  use TypedStruct

  import FCIdentity.{Changeset, Support}

  alias FCIdentity.DefaultLocaleKeeper
  alias FCIdentity.Translation
  alias FCIdentity.{
    UserRegistrationRequested,
    UserAdded,
    UserRegistered,
    UserDeleted,
    PasswordResetTokenGenerated,
    PasswordChanged,
    UserRoleChanged,
    UserInfoUpdated,
    EmailVerificationTokenGenerated,
    EmailVerified
  }

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :default_account_id, String.t()

    field :type, String.t()
    field :status, String.t()
    field :username, String.t()
    field :password_hash, String.t()
    field :email, String.t()

    field :first_name, String.t()
    field :last_name, String.t()
    field :name, String.t()

    field :role, String.t()

    field :password_reset_token, String.t()
    field :password_reset_token_expires_at, DateTime.t()

    field :email_verified, boolean, default: false
    field :email_verification_token, String.t()
    field :email_verification_token_expires_at, DateTime.t()

    field :custom_data, map, default: %{}
    field :translations, map, default: %{}
  end

  def translatable_fields do
    [:custom_data]
  end

  def apply(state, %UserRegistrationRequested{}), do: state

  def apply(state, %UserAdded{} = event) do
    %{state | id: event.user_id}
    |> struct_merge(event)
  end

  def apply(state, %UserRegistered{} = event) do
    %{state | status: "active", default_account_id: event.default_account_id}
  end

  def apply(state, %UserDeleted{}) do
    %{state | status: "removed"}
  end

  def apply(state, %PasswordResetTokenGenerated{} = event) do
    {:ok, datetime, 0} = DateTime.from_iso8601(event.expires_at)

    %{state | password_reset_token: event.token, password_reset_token_expires_at: datetime}
  end

  def apply(state, %EmailVerificationTokenGenerated{} = event) do
    {:ok, datetime, 0} = DateTime.from_iso8601(event.expires_at)

    %{state |
      email_verified: false,
      email_verification_token: event.token,
      email_verification_token_expires_at: datetime
    }
  end

  def apply(state, %PasswordChanged{} = event) do
    %{state |
      password_hash: event.new_password_hash,
      password_reset_token: nil,
      password_reset_token_expires_at: nil
    }
  end

  def apply(state, %UserRoleChanged{} = event) do
    %{state | role: event.role}
  end

  def apply(state, %UserInfoUpdated{locale: locale} = event) do
    default_locale = DefaultLocaleKeeper.get(state.account_id)

    state
    |> cast(event, event.effective_keys)
    |> Translation.put_change(translatable_fields(), locale, default_locale)
    |> apply_changes()
  end

  def apply(state, %EmailVerified{}) do
    %{state |
      email_verified: true,
      email_verification_token: nil,
      email_verification_token_expires_at: nil
    }
  end
end