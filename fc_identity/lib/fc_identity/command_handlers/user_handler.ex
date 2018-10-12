defmodule FCIdentity.UserHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import UUID
  import Comeonin.Argon2
  import FCSupport.{Validation, Normalization}
  import FCIdentity.UserPolicy

  alias FCIdentity.UsernameStore
  alias FCIdentity.{
    RegisterUser,
    AddUser,
    DeleteUser,
    GeneratePasswordResetToken,
    ChangePassword,
    ChangeUserRole,
    UpdateUserInfo,
    GenerateEmailVerificationToken,
    VerifyEmail
  }
  alias FCIdentity.{
    UserRegistrationRequested,
    FinishUserRegistration,
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

  def handle(%{id: nil} = state, %RegisterUser{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%UserRegistrationRequested{})
    |> unwrap_ok()
  end

  def handle(_, %RegisterUser{}), do: {:error, {:already_registered, :user}}

  def handle(%{id: nil} = state, %AddUser{} = cmd) do
    cmd
    |>  authorize(state)
    ~>  trim_strings()
    ~>  downcase_strings([:username, :email])
    ~>  put_name()
    ~>> validate(name: [presence: true])
    ~>> validate_username()
    ~>  merge_to(%UserAdded{type: cmd._type_})
    ~>  put_password_hash(cmd)
    |>  unwrap_ok()
  end

  def handle(_, %AddUser{}), do: {:error, {:already_exist, :user}}

  def handle(%{id: nil}, _), do: {:error, {:not_found, :user}}

  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :user}}

  def handle(%{id: user_id} = state, %FinishUserRegistration{} = cmd) do
    %UserRegistered{
      user_id: user_id,
      default_account_id: state.account_id,
      username: state.username,
      password_hash: state.password_hash,
      email: state.email,
      is_term_accepted: cmd.is_term_accepted,
      first_name: state.first_name,
      last_name: state.last_name,
      name: state.name
    }
  end

  def handle(state, %DeleteUser{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%UserDeleted{})
    |> unwrap_ok()
  end

  def handle(_, %GeneratePasswordResetToken{} = cmd) do
    %PasswordResetTokenGenerated{
      user_id: cmd.user_id,
      token: uuid4(),
      expires_at: to_utc_iso8601(cmd.expires_at)
    }
  end

  def handle(state, %GenerateEmailVerificationToken{} = cmd) do
    expires_at = to_utc_iso8601(cmd.expires_at)

    cmd
    |> authorize(state)
    ~> merge_to(%EmailVerificationTokenGenerated{token: uuid4(), expires_at: expires_at}, except: [:expires_at])
    |> unwrap_ok()
  end

  def handle(state, %VerifyEmail{} = cmd) do
    cmd
    |>  authorize(state)
    ~>> validate_verification_token(state)
    ~>  merge_to(%EmailVerified{})
    |>  unwrap_ok()
  end

  def handle(state, %ChangePassword{} = cmd) do
    cmd
    |>  authorize(state)
    ~>> validate_current_password(state)
    ~>> validate_reset_token(state)
    ~>  merge_to(%PasswordChanged{new_password_hash: hashpwsalt(cmd.new_password)})
    |>  unwrap_ok()
  end

  def handle(state, %ChangeUserRole{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%UserRoleChanged{})
    |> unwrap_ok()
  end

  def handle(state, %UpdateUserInfo{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%UserInfoUpdated{})
    |> unwrap_ok()
  end

  defp put_name(%{name: name} = cmd) when byte_size(name) > 0 do
    cmd
  end

  defp put_name(cmd) do
    name = String.trim("#{cmd.first_name} #{cmd.last_name}")
    %{cmd | name: name}
  end

  defp validate_username(cmd) do
    unless UsernameStore.exist?(cmd.username) do
      {:ok, cmd}
    else
      {:error, {:validation_failed, [{:error, :username, :already_exist}]}}
    end
  end

  defp put_password_hash(event, %{password: password}) when byte_size(password) > 0 do
    %{event | password_hash: hashpwsalt(password)}
  end

  defp put_password_hash(event, _), do: event

  defp validate_current_password(%{current_password: cp} = cmd, %{password_hash: ph}) when is_binary(cp) do
    if checkpw(cp, ph) do
      {:ok, cmd}
    else
      {:error, {:validation_failed, [{:error, :current_password, :invalid}]}}
    end
  end

  defp validate_current_password(cmd, _), do: {:ok, cmd}

  defp validate_reset_token(%{reset_token: reset_token} = cmd, state) when is_binary(reset_token) do
    cond do
      is_reset_token_valid?(reset_token, state) ->
        {:ok, cmd}

      reset_token != state.password_reset_token ->
        {:error, {:validation_failed, [{:error, :reset_token, :invalid}]}}

      !Timex.before?(Timex.now(), state.password_reset_token_expires_at) ->
        {:error, {:validation_failed, [{:error, :reset_token, :expired}]}}
    end
  end

  defp validate_reset_token(cmd, _), do: {:ok, cmd}

  defp is_reset_token_valid?(reset_token, state) do
    reset_token == state.password_reset_token && Timex.before?(Timex.now(), state.password_reset_token_expires_at)
  end

  defp validate_verification_token(%{verification_token: verification_token} = cmd, state) when is_binary(verification_token) do
    cond do
      is_verification_token_valid?(verification_token, state) ->
        {:ok, cmd}

      verification_token != state.email_verification_token ->
        {:error, {:validation_failed, [{:error, :verification_token, :invalid}]}}

      !Timex.before?(Timex.now(), state.email_verification_token_expires_at) ->
        {:error, {:validation_failed, [{:error, :verification_token, :expired}]}}
    end
  end

  defp validate_verification_token(cmd, _), do: {:ok, cmd}

  defp is_verification_token_valid?(verification_token, state) do
    verification_token == state.email_verification_token && Timex.before?(Timex.now(), state.password_reset_token_expires_at)
  end
end