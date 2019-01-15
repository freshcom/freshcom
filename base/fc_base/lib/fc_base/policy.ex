defmodule FCBase.Policy do
  use OK.Pipe

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