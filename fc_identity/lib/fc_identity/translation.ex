defmodule FCIdentity.Translation do
  alias FCIdentity.Changeset

  @spec put_change(Changeset.t, list, String.t, String.t) :: Changeset.t
  def put_change(changeset, translatable_fields, locale \\ nil, default_locale \\ nil)
  def put_change(changeset, _, nil, nil), do: changeset
  def put_change(changeset, _, _, nil), do: changeset
  def put_change(changeset, _, locale, default_locale) when locale == default_locale, do: changeset
  def put_change(changeset, translatable_fields, locale, _) do
    put_translations(changeset, translatable_fields, locale)
  end

  defp put_translations(changeset, translatable_fields, locale) do
    translations = Changeset.get_field(changeset, :translations)

    locale_struct = Map.get(translations, locale, %{})
    new_locale_struct =
      changeset.changes
      |> Map.take(translatable_fields)
      |> Map.new(fn({k, v}) -> { Atom.to_string(k), v } end)

    merged_locale_struct = Map.merge(locale_struct, new_locale_struct)
    new_translations = Map.merge(translations, %{ locale => merged_locale_struct })

    changeset = Enum.reduce(translatable_fields, changeset, fn(field_name, acc) -> Changeset.delete_change(acc, field_name) end)
    Changeset.put_change(changeset, :translations, new_translations)
  end
end