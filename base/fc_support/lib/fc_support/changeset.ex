defmodule FCSupport.Changeset do
  @moduledoc """
  A light weight changeset implementation similar to the one provided by Ecto.
  """

  use TypedStruct
  alias FCSupport.Changeset

  typedstruct do
    field :data, map
    field :changes, map, default: %{}
  end

  @spec cast(struct, struct) :: Changeset.t()
  def cast(data, %{effective_keys: effective_keys} = event) do
    fields = Map.from_struct(event)

    Enum.reduce(fields, %__MODULE__{data: data}, fn({k, v}, acc) ->
      if Enum.member?(effective_keys, k) do
        put_change(acc, k, v)
      else
        acc
      end
    end)
  end

  def get_field(%{data: data} = changeset, key) do
    get_change(changeset, key) || Map.get(data, key)
  end

  def get_change(%__MODULE__{changes: changes}, key) do
    changes[key]
  end

  def put_change(%__MODULE__{data: data, changes: changes} = changeset, key, value) do
    changes =
      if Map.has_key?(data, key) && (value != Map.get(data, key)) do
        Map.put(changes, key, value)
      else
        changes
      end

    %{changeset | changes: changes}
  end

  def delete_change(%__MODULE__{changes: changes} = changeset, key) do
    changes = Map.drop(changes, [key])
    %{changeset | changes: changes}
  end

  def apply_changes(%{data: data, changes: changes}) do
    struct(data, changes)
  end
end