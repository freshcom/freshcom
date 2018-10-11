defmodule FCIdentity.RequesterIdentification do
  @behaviour Commanded.Middleware

  alias Commanded.Middleware.Pipeline
  alias FCIdentity.RoleKeeper
  alias FCIdentity.TypeKeeper

  def before_dispatch(%Pipeline{} = pipeline) do
    %{pipeline | command: identify(pipeline.command)}
  end

  def identify(%{requester_role: nil, account_id: nil} = cmd) do
    %{cmd | requester_role: "anonymous"}
  end

  def identify(%{requester_role: nil, account_id: _, requester_id: nil} = cmd) do
    %{cmd | requester_role: "guest"}
  end

  def identify(%{requester_role: nil, account_id: _, requester_id: requester_id, requester_type: nil} = cmd) do
    task = Task.async(fn -> TypeKeeper.get(requester_id) end)
    role = RoleKeeper.get(cmd.requester_id, cmd.account_id)
    type = Task.await(task)

    %{cmd | requester_type: type, requester_role: role}
  end

  def identify(%{requester_role: nil, account_id: _} = cmd) do
    %{cmd | requester_role: "guest"}
  end

  def identify(cmd), do: cmd

  def after_dispatch(pipeline), do: pipeline
  def after_failure(pipeline), do: pipeline
end