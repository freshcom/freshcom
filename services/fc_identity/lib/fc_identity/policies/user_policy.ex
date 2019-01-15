defmodule FCIdentity.UserPolicy do
  @moduledoc false

  use FCBase, :policy

  alias FCIdentity.{
    RegisterUser,
    AddUser,
    DeleteUser,
    GeneratePasswordResetToken,
    ChangePassword,
    ChangeUserRole,
    UpdateUserInfo,
    ChangeDefaultAccount,
    GenerateEmailVerificationToken,
    VerifyEmail
  }

  def authorize(%AddUser{requester_role: role} = cmd, _) when role in @admin_roles,
    do: {:ok, cmd}

  def authorize(%RegisterUser{} = cmd, _),
    do: {:ok, cmd}

  def authorize(%GeneratePasswordResetToken{} = cmd, state) do
    cond do
      state.type == "standard" && cmd.client_type == "system" ->
        {:ok, cmd}

      state.type == "standard" ->
        {:error, :access_denied}

      state.type == "managed" ->
        {:ok, cmd}

      true ->
        {:error, :access_denied}
    end
  end

  def authorize(%ChangePassword{} = cmd, state) do
    cond do
      # Standard user can change their own password through system app
      state.type == "standard" && cmd.requester_id == cmd.user_id && cmd.client_type == "system" ->
        {:ok, cmd}

      # Standard user can reset their password through system app
      state.type == "standard" && is_nil(cmd.requester_id) && cmd.client_type == "system" ->
        {:ok, cmd}

      # Standard user's password cannot be changed in any other way
      state.type == "standard" ->
        {:error, :access_denied}

      # Managed user can change their own password
      cmd.requester_id && cmd.requester_id == cmd.user_id ->
        {:ok, cmd}

      # Managed user can reset their password
      is_nil(cmd.requester_id) ->
        {:ok, cmd}

      # Password of customer can be changed by user with specific roles
      state.role == "customer" ->
        default(cmd, state, @customer_management_roles)

      # Owner's password cannot be changed by other user
      state.role == "owner" ->
        {:error, :access_denied}

      # Password of managed users can be changed by admin users
      true ->
        default(cmd, state, @admin_roles)
    end
  end

  def authorize(%UpdateUserInfo{} = cmd, state) do
    cond do
      state.type == "standard" && cmd.requester_id == cmd.user_id ->
        {:ok, cmd}

      state.type == "standard" ->
        {:error, :access_denied}

      cmd.requester_id == cmd.user_id ->
        {:ok, cmd}

      state.role == "customer" ->
        default(cmd, state, @customer_management_roles)

      true ->
        default(cmd, state, @admin_roles)
    end
  end

  def authorize(
        %ChangeDefaultAccount{
          requester_id: rid,
          requester_type: "standard",
          requester_role: "owner",
          client_type: "system",
          user_id: uid
        } = cmd,
        _
      )
      when rid == uid,
      do: {:ok, cmd}

  def authorize(%DeleteUser{} = cmd, state) do
    cond do
      state.type == "standard" ->
        {:error, :access_denied}

      cmd.requester_id == cmd.user_id ->
        {:error, :access_denied}

      true ->
        default(cmd, state, @admin_roles)
    end
  end

  def authorize(%ChangeUserRole{} = cmd, state) do
    cond do
      state.type == "standard" ->
        {:error, :access_denied}

      cmd.requester_id == cmd.user_id ->
        {:error, :access_denied}

      true ->
        default(cmd, state, @admin_roles)
    end
  end

  def authorize(%GenerateEmailVerificationToken{} = cmd, state) do
    cond do
      state.type == "standard" && cmd.requester_id == cmd.user_id ->
        {:ok, cmd}

      state.type == "standard" ->
        {:error, :access_denied}

      cmd.requester_id == cmd.user_id ->
        {:ok, cmd}

      state.role == "customer" ->
        default(cmd, state, @customer_management_roles)

      true ->
        default(cmd, state, @admin_roles)
    end
  end

  def authorize(%VerifyEmail{} = cmd, state) do
    cond do
      state.type == "standard" && cmd.requester_id == cmd.user_id && cmd.client_type == "system" ->
        {:ok, cmd}

      state.type == "standard" && is_nil(cmd.requester_id) && cmd.client_type == "system" ->
        {:ok, cmd}

      state.type == "standard" ->
        {:error, :access_denied}

      cmd.requester_id == cmd.user_id ->
        {:ok, cmd}

      state.role == "customer" ->
        default(cmd, state, @customer_management_roles)

      true ->
        default(cmd, state, @admin_roles)
    end
  end

  def authorize(_, _), do: {:error, :access_denied}
end
