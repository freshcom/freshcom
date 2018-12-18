defmodule Freshcom.Context do
  use OK.Pipe

  import Ecto.Query
  import FCSupport.Normalization, only: [atomize_keys: 2, stringify_list: 1]

  alias Ecto.{Query, Queryable}
  alias FCSupport.Struct
  alias Freshcom.{Request, Response}
  alias Freshcom.{Repo, Filter, Include, Projector, Router}
  alias Freshcom.{Account, User, App}

  @type resp :: {:ok, Response.t()} | {:error, Response.t()} | {:error, :not_found} | {:error, :access_denied}

  @spec to_response({:ok, any} | {:error, any}) :: {:ok | :error, Response.t()}
  def to_response({:ok, nil}) do
    {:error, :not_found}
  end

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

  def to_response(data) when is_list(data) or is_map(data) or is_integer(data) do
    {:ok, %Response{data: data}}
  end

  def to_response(result) do
    raise "unexpected result returned: #{inspect result}"
  end

  @spec dispatch_and_wait(struct, module, function) :: {:ok | :error, any}
  def dispatch_and_wait(cmd, event_module, wait_func) do
    Projector.subscribe()

    result =
      cmd
      |> Router.dispatch(include_execution_result: true, consistency: :strong)
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
    fields = atomize_keys(req.fields, Map.keys(cmd))
    effective_keys =
      fields
      |> Map.keys()
      |> stringify_list()

    cmd
    |> Struct.merge(fields)
    |> Struct.put(:requester_id, req.requester_id)
    |> Struct.put(:requester_role, req._role_)
    |> Struct.put(:client_id, App.bare_id(req.client_id))
    |> Struct.put(:account_id, Account.bare_id(req.account_id))
    |> Struct.put(:effective_keys, effective_keys)
    |> Struct.put(:locale, req.locale)
  end

  def expand(req) do
    req
    |> Map.put(:client_id, App.bare_id(req.client_id))
    |> Map.put(:account_id, Account.bare_id(req.account_id))
    |> put_account()
    |> put_default_locale()
    |> put_requester()
    |> put_role()
    |> put_client()
  end

  defp put_account(%{account_id: nil} = req), do: %{req | _account_: nil}
  defp put_account(%{account_id: id} = req), do: %{req | _account_: Repo.get_by(Account, id: id, status: "active")}

  defp put_default_locale(%{_account_: nil} = req), do: %{req | _default_locale_: nil}
  defp put_default_locale(%{_account_: account} = req), do: %{req | _default_locale_: account.default_locale}

  defp put_requester(%{_account_: nil} = req), do: %{req | _requester_: nil}
  defp put_requester(%{requester_id: nil} = req), do: %{req | _requester_: nil}

  defp put_requester(%{requester_id: id, _account_: %{owner_id: owner_id}} = req) when id == owner_id,
    do: %{req | _requester_: Repo.get_by(User, id: id)}

  defp put_requester(%{requester_id: id, _account_: %{mode: "live"} = account} = req),
    do: %{req | _requester_: Repo.get_by(User, id: id, account_id: account.id)}

  defp put_requester(%{requester_id: id, _account_: %{mode: "test"} = account} = req) do
    requester = Repo.get_by(User, id: id, account_id: account.id)
    requester = requester || Repo.get_by(User, id: id, account_id: account.live_account_id)

    %{req | _requester_: requester}
  end

  defp put_role(%{_account_: nil, _role_: nil} = req), do: %{req | _role_: "anonymous"}
  defp put_role(%{_requester_: nil, _role_: nil} = req), do: %{req | _role_: "guest"}
  defp put_role(%{_requester_: %{role: role}, _role_: nil} = req), do: %{req | _role_: role}
  defp put_role(req), do: req

  defp put_client(%{client_id: nil} = req), do: %{req | _client_: nil}
  defp put_client(%{client_id: client_id, account_id: account_id} = req) do
    client = Repo.get_by(App, id: App.bare_id(client_id))

    cond do
      is_nil(client) ->
        %{req | _client_: nil}

      client.type == "system" ->
        %{req | _client_: client}

      client.type == "standard" && client.account_id == account_id ->
        %{req | _client_: client}

      true ->
        %{req | _client_: nil}
    end
  end

  @spec preload(nil | list | struct, Request.t()) :: struct | [struct] | nil
  def preload(nil, _), do: nil
  def preload([], _), do: []

  def preload(structs, req) when is_list(structs) do
    struct = Enum.at(structs, 0)
    preloads = Include.to_ecto_preloads(struct.__struct__, req.include, req._include_filters_)

    Repo.preload(structs, preloads)
  end

  def preload(struct, req) do
    preloads = Include.to_ecto_preloads(struct.__struct__, req.include, req._include_filters_)

    Repo.preload(struct, preloads)
  end

  @spec to_query(Request.t(), Query.t() | map) :: Query.t()
  def to_query(req, %Query{} = query) do
    {_, queryable} = query.from
    translatable_fields = if Keyword.has_key?(queryable.__info__(:functions), :translatable_fields) do
      queryable.translatable_fields()
    else
      []
    end

    query
    |> for_account(req.account_id)
    |> identify(req.identifiers, req._identifiable_fields_)
    |> filter(req.filter, req._filterable_fields_)
    |> search(req.search, req._searchable_fields_, req.locale, req._default_locale_, translatable_fields)
    |> sort(req.sort, req._sortable_fields_)
    |> paginate(req.pagination)
  end

  def to_query(req, queryable) do
    to_query(req, Queryable.to_query(queryable))
  end

  @spec for_account(Query.t(), String.t() | nil) :: Query.t()
  def for_account(query, nil), do: query

  def for_account(query, account_id) do
    from(q in query, where: q.account_id == ^account_id)
  end

  @spec identify(Query.t(), map, [String.t()]) :: Query.t()
  def identify(query, identifiers, identifiable_fields) do
    filter =
      Enum.reduce(identifiers, [], fn({k, v}, acc) ->
        acc ++ [%{k => v}]
      end)

    Filter.attr_only(query, filter, identifiable_fields)
  end

  @spec filter(Query.t(), [map], [String.t()]) :: Query.t()
  def filter(query, filter, filterable_fields) do
    if has_assoc_field(filterable_fields) do
      Filter.with_assoc(query, filter, filterable_fields)
    else
      Filter.attr_only(query, filter, filterable_fields)
    end
  end

  defp has_assoc_field(:all), do: false

  defp has_assoc_field(fields) do
    Enum.any?(fields, fn(field) ->
      Filter.is_assoc(field)
    end)
  end

  @spec search(Query.t(), String.t(), [String.t()], String.t(), String.t(), [String.t()]) :: Query.t()
  def search(query, nil, _, _, _, _), do: query
  def search(query, "", _, _, _, _), do: query
  def search(query, _, [], _, _, _), do: query

  def search(query, keyword, searchable_fields, locale, default_locale, _) when is_nil(locale) or (locale == default_locale) do
    search_fields(query, keyword, searchable_fields)
  end

  def search(query, keyword, searchable_fields, locale, translatable_fields) do
    search_translations(query, keyword, searchable_fields, locale, translatable_fields)
  end

  defp search_fields(query, keyword, [field | rest]) do
    keyword = "%#{keyword}%"
    field = String.to_existing_atom(field)
    dynamics = dynamic([q], ilike(fragment("?::varchar", field(q, ^field)), ^keyword))

    dynamics =
      Enum.reduce(rest, dynamics, fn(field, dynamics) ->
        field = String.to_existing_atom(field)
        dynamic([q], ^dynamics or ilike(fragment("?::varchar", field(q, ^field)), ^keyword))
      end)

    from(q in query, where: ^dynamics)
  end

  # TODO: use dynamic
  defp search_translations(query, keyword, searchable_fields, locale, translatable_fields) do
    keyword = "%#{keyword}%"

    Enum.reduce(searchable_fields, query, fn(field, query) ->
      if Enum.member?(translatable_fields, field) do
        from q in query, or_where: ilike(fragment("?->?->>?", q.translations, ^locale, ^field), ^keyword)
      else
        field = String.to_existing_atom(field)
        from q in query, or_where: ilike(fragment("?::varchar", field(q, ^field)), ^keyword)
      end
    end)
  end

  @spec sort(Query.t(), [map], [String.t()]) :: Query.t()
  def sort(query, [], _), do: query
  def sort(query, _, []), do: query

  def sort(query, sort, sortable_fields) do
    orderings =
      Enum.reduce(sort, [], fn(sorter, acc) ->
        {field, ordering} = Enum.at(sorter, 0)

        if (field in sortable_fields) && (ordering in ["asc", "desc"]) do
          acc ++ [{String.to_existing_atom(ordering), String.to_existing_atom(field)}]
        else
          acc
        end
      end)

    order_by(query, ^orderings)
  end

  @spec paginate(Query.t(), map | nil) :: Query.t()
  def paginate(query, %{number: number} = pagination) when is_integer(number) do
    size = pagination[:size] || 25
    offset = size * (number - 1)

    query
    |> limit(^size)
    |> offset(^offset)
  end

  def paginate(query, pagination) do
    before_sid = sid(query, pagination[:before_id])
    after_sid = sid(query, pagination[:after_id])
    size = pagination[:size] || 25
    query = limit(query, ^size)

    if before_sid || after_sid do
      query
      |> exclude(:order_by)
      |> order_by(desc: :sid)
      |> apply_cursor(before_sid, after_sid)
    else
      query
    end
  end

  def pagination(query, nil), do: query

  defp apply_cursor(query, before_sid, _) when is_integer(before_sid) do
    where(query, [q], q.sid > ^before_sid)
  end

  defp apply_cursor(query, _, after_sid) when is_integer(after_sid) do
    where(query, [q], q.sid < ^after_sid)
  end

  defp sid(_, nil), do: nil

  defp sid(query, id) do
    {_, queryable} = query.from
    data = Repo.get(queryable, id)

    if data, do: data.sid, else: nil
  end
end