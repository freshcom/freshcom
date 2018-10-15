defmodule FCSupport.ControlFlow do
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

  def tt_wrap({:error, any}), do: {:error, any}
  def tt_wrap(any), do: {:ok, any}
end