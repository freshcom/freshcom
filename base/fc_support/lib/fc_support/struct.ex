defmodule FCSupport.Struct do
  @doc """
  Merge the `src` struct into the `dest` struct. Keys that are not part of `dest`
  will be safely ignored.
  This function is different than `struct/2` as that function will raise if the
  second argument is a struct.
  """
  def merge(dest, src, opts \\ []) do
    keys = opts[:only] || Map.keys(dest) -- [:__struct__]
    excepts = opts[:except] || []
    keys = keys -- excepts

    filtered_src = Map.take(src, keys)
    struct(dest, filtered_src)
  end

  @doc """
  Similar to `merge/3` except `dest` and `src` are reversed, useful when
  using pipes.
  """
  def merge_to(src, dest, opts \\ []) do
    merge(dest, src, opts)
  end

  @doc """
  Similar to `Map.put/3` except this function will safely ignore any given `key`
  that is not part of the given `struct`.
  """
  @spec put(struct, atom, any) :: struct
  def put(struct, key, value) do
    keys = Map.keys(struct)

    if Enum.member?(keys, key) do
      Map.put(struct, key, value)
    else
      struct
    end
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

  defp stringify_list(l) do
    Enum.reduce(l, [], fn(item, acc) ->
      if is_atom(item) do
        acc ++ [Atom.to_string(item)]
      else
        acc ++ [item]
      end
    end)
  end
end