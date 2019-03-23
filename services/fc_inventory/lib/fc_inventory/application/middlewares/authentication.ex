defmodule FCInventory.Authentication do
  @behaviour Commanded.Middleware

  alias Commanded.Middleware.Pipeline
  alias FCInventory.{AccountService, StaffService}

  def before_dispatch(%Pipeline{} = pipeline) do
    case authenticate(pipeline.command) do
      {:error, _} = error ->
        pipeline
        |> Pipeline.respond(error)
        |> Pipeline.halt()

      cmd ->
        %{pipeline | command: cmd}
    end
  end

  # def authenticate(%{staff_id: nil}), do: {:error, {:unauthenticated, :staff}}
  # def authenticate(%{account_id: nil}), do: {:error, {:unauthenticated, :account}}

  def authenticate(%{_account_: _, _staff_: _} = cmd) do
    with {:ok, account} <- AccountService.find(cmd.account_id),
         {:ok, staff} <- StaffService.find(account, cmd.staff_id)
    do
      %{cmd | _account_: account, _staff_: staff}
    else
      {:error, {:not_found, level}} ->
        {:error, {:unauthenticated, level}}

      other ->
        other
    end
  end

  def authenticate(cmd), do: cmd

  def after_dispatch(pipeline), do: pipeline
  def after_failure(pipeline), do: pipeline
end