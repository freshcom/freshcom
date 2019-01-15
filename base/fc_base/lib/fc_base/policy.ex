defmodule FCBase.Policy do
  use OK.Pipe

  def only(cmd, :system_app),
    do: only(cmd, &(&1.client_type == "system"))

  def only(cmd, :standard_user),
    do: only(cmd, &(&1.requester_type == "standard"))

  def only(cmd, :owner_role),
    do: only(cmd, &(&1.requester_role == "owner"))

  def only(cmd, condition) do
    if condition.(cmd) do
      {:ok, cmd}
    else
      {:error, :access_denied}
    end
  end

  def default(cmd, state, roles) do
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