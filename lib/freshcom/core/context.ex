defmodule Freshcom.Context do
  use OK.Pipe

  import Ecto.Query

  alias FCSupport.Struct
  alias Freshcom.{Request, Response}
  alias Freshcom.{Repo, Filter, Include, Projector, Router}

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

  @spec dispatch_and_wait(struct, module, function) :: {:ok | :error, any}
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

  defp normalize_wait_result({:error, {:timeout, _}}), do: {:error, {:timeout, :projection_wait}}
  defp normalize_wait_result(other), do: other

  defp find_event(events, module) do
    Enum.find(events, &(&1.__struct__ == module))
  end

  @spec to_command(Request.t(), struct) :: struct
  def to_command(req, cmd) do
    fields = Struct.atomize_keys(req.fields, Map.keys(cmd))

    cmd
    |> Struct.merge(fields)
    |> Struct.put(:requester_id, req.requester[:id])
    |> Struct.put(:account_id, req.requester[:account_id])
    |> Struct.put(:effective_keys, Map.keys(fields))
    |> Struct.put(:locale, req.locale)
  end

  @spec preload(nil | list | struct, Request.t()) :: struct | [struct] | nil
  def preload(nil, _), do: nil
  def preload([], _), do: []

  def preload(struct_or_structs, req) do
    struct = Enum.at(struct_or_structs, 0)
    preloads = Include.to_ecto_preloads(struct.__struct__, req.include, req._include_filters_)

    Repo.preload(struct_or_structs, preloads)
  end

  def to_query(req, query) do
    query
    |> for_account(req.requester[:account_id])
    |> filter_by(req.filter, req._filterable_fields_)
    |> search(req.search, req._searchable_fields_)
    |> sort(req.sort)
    |> paginate(req.pagination)
  end

  defp for_account(query, nil), do: query

  defp for_account(query, account_id) do
    from(q in query, where: q.account_id == ^account_id)
  end

  defp filter_by(query, filter, filterable_fields) do
    if has_assoc_field(filterable_fields) do
      Filter.with_assoc(query, filter, filterable_fields)
    else
      Filter.attr_only(query, filter, filterable_fields)
    end
  end

  defp has_assoc_field(fields) do
    Enum.any?(fields, fn(field) ->
      Filter.is_assoc(field)
    end)
  end

  defp paginate(query, pagination) do
    query
  end

  defp sort(query, sort) do
    query
  end

  defp search(query, search, searchable_fields) do
    query
  end
end