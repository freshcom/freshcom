defmodule FCBase.ClientIdentification do
  @behaviour Commanded.Middleware

  alias Commanded.Middleware.Pipeline
  alias FCStateStorage.GlobalStore.AppStore

  def before_dispatch(%Pipeline{} = pipeline) do
    %{pipeline | command: identify(pipeline.command)}
  end

  def identify(%{client_id: nil} = cmd) do
    %{cmd | client_type: "unkown"}
  end

  def identify(%{client_id: client_id, account_id: account_id} = cmd) do
    client = AppStore.get(client_id)

    cond do
      is_nil(client) ->
        %{cmd | client_type: "unkown"}

      client.type == "system" ->
        %{cmd | client_type: client.type}

      client.type == "standard" && client.account_id == account_id ->
        %{cmd | client_type: client.type}

      true ->
        %{cmd | client_type: "unkown"}
    end
  end

  def identify(cmd), do: cmd

  def after_dispatch(pipeline), do: pipeline
  def after_failure(pipeline), do: pipeline
end