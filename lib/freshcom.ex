defmodule Freshcom do
  import FCSupport.Struct

  use OK.Pipe

  alias Freshcom.{Router, Repo}
  alias FCIdentity.RegisterUser

  def register_user(%{fields: fields}) do
    {:ok, result} = %RegisterUser{}
    |>  merge(fields)
    |>  Router.dispatch(consistency: :strong, include_execution_result: true)
    |>  IO.inspect()

    wait_for(result, "9708460c-a25a-4a14-b049-ea78af279746")
    Repo.all(Freshcom.User)
  end

  def wait_for(result, handler, timeout \\ 5_000) do
    stream_id = Map.get(result, :aggregate_uuid)
    stream_version = Map.get(result, :aggregate_version) + 5

    IO.inspect Commanded.Subscriptions.handled?(stream_id, 3, consistency: :strong)
    IO.inspect stream_id
    IO.inspect stream_version
    Commanded.Subscriptions.wait_for(
      stream_id,
      stream_version,
      [consistency: :strong],
      timeout
    )
  end
end