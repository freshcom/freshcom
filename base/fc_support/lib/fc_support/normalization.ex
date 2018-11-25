defmodule FCSupport.Normalization do
  def to_utc_iso8601(datetime) do
    datetime
    |> Timex.Timezone.convert("UTC")
    |> DateTime.to_iso8601()
  end

  def normalize_by(map, root_key, key, test_func, normalize_func) do
    value =
      map
      |> Map.get(root_key)
      |> Map.get(key)

    if test_func.(value) do
      root_value =
        map
        |> Map.get(root_key)
        |> Map.put(key, normalize_func.(value))

      Map.put(map, root_key, root_value)
    else
      map
    end
  end

  @doc """
  Trim all values in the struct that are string.
  """
  def trim_strings(struct) do
    Enum.reduce(Map.keys(struct), struct, fn(k, acc) ->
      v = Map.get(struct, k)

      if String.valid?(v) do
        Map.put(acc, k, String.trim(v))
      else
        acc
      end
    end)
  end

  @doc """
  Downcase values of the given keys in the struct. Non-string values will be
  safely ignored.

  If `keys` not provided, defaults to all keys of the given `struct`.
  """
  def downcase_strings(struct, keys \\ nil) do
    keys = keys || Map.keys(struct)

    Enum.reduce(keys, struct, fn(k, acc) ->
      v = Map.get(struct, k)

      if String.valid?(v) do
        Map.put(acc, k, String.downcase(v))
      else
        acc
      end
    end)
  end

  def atomize_keys(m, permitted \\ nil) do
    permitted_atom = permitted || Map.keys(m)
    permitted_string = stringify_list(permitted)

    Enum.reduce(m, %{}, fn({k, v}, acc) ->
      cond do
        is_binary(k) && Enum.member?(permitted_string, k) ->
          Map.put(acc, String.to_existing_atom(k), v)

        is_atom(k) && Enum.member?(permitted_atom, k) ->
          Map.put(acc, k, v)

        true ->
          acc
      end
    end)
  end

  def stringify_list(l) do
    Enum.reduce(l, [], fn(item, acc) ->
      if is_atom(item) do
        acc ++ [Atom.to_string(item)]
      else
        acc ++ [item]
      end
    end)
  end

  def atomize_list(l) do
    Enum.reduce(l, [], fn(item, acc) ->
      if is_binary(item) do
        acc ++ [String.to_existing_atom(item)]
      else
        acc ++ [item]
      end
    end)
  end
end