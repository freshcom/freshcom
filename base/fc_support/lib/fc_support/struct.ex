defmodule FCSupport.Struct do
  @doc """
  Merge the `src` struct or map into the `dest` struct. Keys that are not part of `dest`
  will be safely ignored.

  If the given `src` is a map with string keys, it will be treated as if the keys
  are given as atom. It will do the conversion safely only convert if the `dest`
  has a matching atom key.

  This function is different than `struct/2` as that function will raise if the
  second argument is a struct.
  """
  @spec merge(struct, struct | map, keyword) :: struct
  def merge(dest, src, opts \\ []) do
    keys = opts[:only] || Map.keys(dest) -- [:__struct__]
    keys = Enum.map(keys, &Atom.to_string/1)

    excepts = opts[:except] || []
    excepts = Enum.map(excepts, &Atom.to_string/1)

    keys = keys -- excepts
    safe_src = Map.take(stringify_keys(src), keys)

    struct(dest, atomize_keys(safe_src))
  end

  @doc """
  Similar to `merge/3` except `dest` and `src` are reversed, useful when
  using pipes.
  """
  def merge_to(src, dest, opts \\ []) do
    merge(dest, src, opts)
  end

  def stringify_keys(%{__struct__: _} = s) do
    stringify_keys(Map.from_struct(s))
  end

  def stringify_keys(m) when is_map(m) do
    Enum.reduce(m, %{}, fn({k, v}, acc) ->
      if is_atom(k) do
        Map.put(acc, Atom.to_string(k), v)
      else
        Map.put(acc, k, v)
      end
    end)
  end

  def atomize_keys(m) do
    Enum.reduce(m, %{}, fn({k, v}, acc) ->
      if is_binary(k) do
        Map.put(acc, String.to_existing_atom(k), v)
      else
        Map.put(acc, k, v)
      end
    end)
  end
end