defmodule FCSupport.Normalization do

  def to_utc_iso8601(datetime) do
    datetime
    |> Timex.Timezone.convert("UTC")
    |> DateTime.to_iso8601()
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
    permitted = permitted || Map.keys(m)
    permitted = stringify_list(permitted)

    Enum.reduce(m, %{}, fn({k, v}, acc) ->
      if is_binary(k) && Enum.member?(permitted, k) do
        Map.put(acc, String.to_existing_atom(k), v)
      else
        Map.put(acc, k, v)
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
end