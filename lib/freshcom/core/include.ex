defmodule Freshcom.Include do
  alias Ecto.Queryable

  def to_preloads(schema, include, filters \\ [])

  def to_preloads(_, [], _), do: []
  def to_preloads(_, nil, _), do: []

  def to_preloads(schema, include, filters) when is_binary(include) do
    to_preloads(schema, to_preload_paths(include), filters)
  end

  def to_preloads(schema, [assoc | rest], filters) do
    to_preloads(schema, assoc, filters) ++ to_preloads(schema, rest, filters)
  end

  def to_preloads(schema, {assoc, nested}, filters) do
    reflection = schema.__schema__(:association, assoc)
    query = Queryable.to_query(reflection.queryable)

    assoc_schema = reflection.related
    nested_preload = to_preloads(assoc_schema, nested, filters)

    Keyword.put([], assoc, {query, nested_preload})
  end

  def to_preloads(schema, assoc, filters) when is_atom(assoc) do
    to_preloads(schema, {assoc, nil}, filters)
  end

  @doc """
  Converts JSON API style include string to a keyword list that can be passed
  in to `BlueJet.Repo.preload`.
  """
  @spec to_preload_paths(String.t()) :: keyword
  def to_preload_paths(include_paths) when byte_size(include_paths) == 0, do: []

  def to_preload_paths(include_paths) do
    preloads = String.split(include_paths, ",")
    preloads = Enum.sort_by(preloads, fn(item) -> length(String.split(item, ".")) end)

    Enum.reduce(preloads, [], fn(item, acc) ->
      preload = to_preload_path(item)

      # If its a chained preload and the root key already exist in acc
      # then we need to merge it.
      with [{key, value}] <- preload,
           true <- Keyword.has_key?(acc, key)
      do
        # Merge chained preload with existing root key
        existing_value = Keyword.get(acc, key)
        index = Enum.find_index(acc, fn(item) ->
          is_tuple(item) && elem(item, 0) == key
        end)

        List.update_at(acc, index, fn(_) ->
          {key, List.flatten([existing_value]) ++ value}
        end)
      else
        _ ->
          acc ++ preload
      end
    end)
  end

  defp to_preload_path(preload) do
    preload =
      preload
      |> Inflex.underscore()
      |> String.split(".")
      |> Enum.map(fn(item) -> String.to_existing_atom(item) end)

    nestify(preload)
  end

  defp nestify(list) when length(list) == 1 do
    [Enum.at(list, 0)]
  end

  defp nestify(list) do
    r_nestify(list)
  end

  defp r_nestify(list) do
    case length(list) do
      1 -> Enum.at(list, 0)
      _ ->
        [head | tail] = list
        Keyword.put([], head, r_nestify(tail))
    end
  end
end