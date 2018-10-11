defmodule FCIdentity.Changeset do
  @moduledoc """
  A light weight changeset implementation similar to the one provided by Ecto.
  """

  use TypedStruct

  typedstruct do
    field :data, map
    field :changes, map, default: %{}
  end

  def cast(data, fields, permitted) do
    Enum.reduce(permitted, %__MODULE__{data: data}, fn(key, acc) ->
      if Map.has_key?(fields, key) do
        put_change(acc, key, Map.get(fields, key))
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