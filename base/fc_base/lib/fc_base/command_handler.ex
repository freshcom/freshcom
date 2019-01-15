defmodule FCBase.CommandHandler do
  def put_original_fields(%{effective_keys: effective_keys} = event, state) do
    fields = Map.from_struct(state)

    original_fields =
      Enum.reduce(fields, %{}, fn {k, v}, acc ->
        str_key = Atom.to_string(k)

        if Enum.member?(effective_keys, str_key) do
          Map.put(acc, str_key, v)
        else
          acc
        end
      end)

    Map.put(event, :original_fields, original_fields)
  end
end