defmodule FCIdentity.Support do
  @doc """
  Unwrap the reuslt out of the tagged tuple if the tag is `:ok`, otherwise
  return the input.
  """
  @spec unwrap_ok({:error, any}) :: {:error, any}
  def unwrap_ok({:error, reason}), do: {:error, reason}

  @spec unwrap_ok({:ok, any}) :: any
  def unwrap_ok({:ok, result}), do: result

  @spec unwrap_ok(any) :: any
  def unwrap_ok(any), do: any

  @doc """
  Merge the `src` struct into the `dest` struct. Keys that are not part of `dest`
  will be safely ignored.

  This function is different than `struct/2` as that function will raise if the
  second argument is a struct.
  """
  def struct_merge(dest, src, keys \\ nil) do
    keys = keys || Map.keys(dest) -- [:__struct__]
    filtered_src = Map.take(src, keys)
    struct(dest, filtered_src)
  end

  @doc """
  Similar to `struct_merge/3` except `dest` and `src` are reversed, useful when
  using pipes.
  """
  def merge_to(src, dest, keys \\ nil) do
    struct_merge(dest, src, keys)
  end
end