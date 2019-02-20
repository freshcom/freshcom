defmodule FCBase.CommandHandler do
  def put_translations(%{locale: locale} = event, _, _, default_locale) when locale == default_locale, do: event
  def put_translations(%{locale: nil} = event, _, _, _), do: event

  def put_translations(%{locale: locale} = event, %{translations: translations}, translatable_fields, _) do
    effective_keys = event.effective_keys

    locale_struct = Map.get(translations, locale, %{})
    new_locale_struct =
      Map.take(event, effective_keys)
      |> Map.take(translatable_fields)
      |> Map.new(fn({k, v}) -> {Atom.to_string(k), v} end)

    merged_locale_struct = Map.merge(locale_struct, new_locale_struct)
    new_translations = Map.merge(translations, %{locale => merged_locale_struct})
    new_effective_keys = (effective_keys -- translatable_fields) ++ [:translations]

    %{event | effective_keys: new_effective_keys, translations: new_translations}
  end

  def put_original_fields(%{effective_keys: effective_keys} = event, state) do
    fields = Map.from_struct(state)

    original_fields =
      Enum.reduce(fields, %{}, fn {k, v}, acc ->
        if Enum.member?(effective_keys, k) do
          Map.put(acc, k, v)
        else
          acc
        end
      end)

    Map.put(event, :original_fields, original_fields)
  end
end