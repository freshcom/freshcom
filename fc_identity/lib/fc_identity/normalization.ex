defmodule FCIdentity.Normalization do

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
end