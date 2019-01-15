defmodule FCIdentity.UserPolicy do
  @moduledoc false

  use OK.Pipe

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

  def authorize(%{requester_role: "sysdev"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "system"} = cmd, _), do: {:ok, cmd}
  def authorize(%{requester_role: "appdev"} = cmd, _), do: {:ok, cmd}
  def authorize(%{client_type: "unkown"}, _), do: {:error, :access_denied}

  def authorize(%AddUser{requester_role: role} = cmd, _) when role in ["owner", "administrator"],
    do: {:ok, cmd}

  def authorize(%RegisterUser{} = cmd, _),
    do: {:ok, cmd}

  def authorize(%GeneratePasswordResetToken{client_type: "system"} = cmd, %{type: "standard"}), do: {:ok, cmd}
  def authorize(%GeneratePasswordResetToken{} = cmd, %{type: "managed"}), do: {:ok, cmd}

  # Changing user's own password
  def authorize(
        %ChangePassword{requester_id: rid, requester_type: "standard", user_id: uid, client_type: "system"} = cmd,
        _
      )
      when rid == uid,
      do: {:ok, cmd}

  def authorize(%ChangePassword{requester_id: rid, requester_type: "managed", user_id: uid} = cmd, _) when rid == uid,
    do: {:ok, cmd}

  # Reseting password
  def authorize(%ChangePassword{requester_id: nil} = cmd, _),
    do: {:ok, cmd}

  # Managing other user's password
  def authorize(%ChangePassword{} = cmd, state),
    do: default_authorize(cmd, state, ["owner", "administrator"])

  # Updating user's own info
  def authorize(%UpdateUserInfo{requester_id: rid, user_id: uid} = cmd, _) when rid == uid,
    do: {:ok, cmd}

  # Support specailist can update customer's info
  def authorize(%UpdateUserInfo{} = cmd, %{role: "customer"} = state),
    do: default_authorize(cmd, state, ["owner", "administrator", "support_specialist"])

  def authorize(%UpdateUserInfo{} = cmd, state),
    do: default_authorize(cmd, state, ["owner", "administrator"])

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

  def authorize(%DeleteUser{} = cmd, state),
    do: default_authorize(cmd, state, ["owner", "administrator"])

  def authorize(%ChangeUserRole{} = cmd, state),
    do: default_authorize(cmd, state, ["owner", "administrator"])

  # User can generate evt for self
  def authorize(%GenerateEmailVerificationToken{requester_id: rid, user_id: uid} = cmd, _) when rid == uid,
    do: {:ok, cmd}

  def authorize(%GenerateEmailVerificationToken{} = cmd, %{role: "customer"} = state),
    do: default_authorize(cmd, state, ["owner", "administrator", "support_specialist"])

  # Using verification token does not require requester to be identified
  def authorize(%VerifyEmail{requester_id: nil} = cmd, _),
    do: {:ok, cmd}

  def authorize(%VerifyEmail{} = cmd, %{role: "customer"} = state),
    do: default_authorize(cmd, state, ["owner", "administrator", "support_specialist"])

  def authorize(%VerifyEmail{} = cmd, state),
    do: default_authorize(cmd, state, ["owner", "administrator"])

  def authorize(_, _), do: {:error, :access_denied}

  defp default_authorize(_, %{role: "owner"}, _), do: {:error, :access_denied}

  defp default_authorize(cmd, state, roles) do
    cmd
    |> authorize_by_account(state.account_id)
    ~>> authorize_by_role(roles)
  end

  defp authorize_by_account(%{account_id: t_aid} = cmd, aid) when t_aid == aid do
    {:ok, cmd}
  end

  defp authorize_by_account(_, _), do: {:error, :access_denied}

  defp authorize_by_role(%{requester_role: role} = cmd, roles) do
    if role in roles do
      {:ok, cmd}
    else
      {:error, :access_denied}
    end
  end

  defp authorize_by_role(_, _), do: {:error, :access_denied}
end
