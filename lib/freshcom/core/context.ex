defmodule Freshcom.Context do
  use OK.Pipe

  alias FCSupport.Struct
  alias Freshcom.Response
  alias Freshcom.{Projector, Router}

  @spec to_response({:ok, any} | {:error, any}) :: {:ok | :error, Response.t()}
  def to_response({:ok, data}) do
    {:ok, %Response{data: data}}
  end

  def to_response({:error, {:validation_failed, errors}}) do
    {:error, %Response{errors: errors}}
  end

  def to_response({:error, {:not_found, _}}) do
    {:error, :not_found}
  end

  def to_response({:error, :access_denied}) do
    {:error, :access_denied}
  end

  def to_response(result) do
    raise "unexpected result returned: #{inspect result}"
  end

  def normalize_wait_result({:error, {:timeout, _}}), do: {:error, {:timeout, :projection_wait}}
  def normalize_wait_result(other), do: other

  def find_event(events, module) do
    Enum.find(events, &(&1.__struct__ == module))
  end

  def dispatch_and_wait(cmd, event_module, wait_func) do
    Projector.subscribe()

    result =
      cmd
      |> Router.dispatch(include_execution_result: true)
      ~> Map.get(:events)
      ~> find_event(event_module)
      ~>> wait_func.()
      |> normalize_wait_result()

    Projector.unsubscribe()

    result
  end

  def to_command(req, cmd) do
    fields = Struct.atomize_keys(req.fields, Map.keys(cmd))

    cmd
    |> Struct.merge(fields)
    |> Struct.put(:requester_id, req.requester[:id])
    |> Struct.put(:account_id, req.requester[:account_id])
    |> Struct.put(:effective_keys, Map.keys(fields))
    |> Struct.put(:locale, req.locale)
  end
end