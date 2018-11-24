defimpl Vex.Blank, for: DateTime do
  def blank?(%DateTime{}), do: false
  def blank?(_), do: true
end

defmodule FCSupport.Validation do
  def validate(struct) do
    settings = struct.__struct__.__vex_validations__()
    validate(struct, settings)
  end

  def validate(struct, effective_keys: e_keys) do
    settings =
      struct.__struct__.__vex_validations__()
      |> Map.take(e_keys)

    validate(struct, settings)
  end

  def validate(struct, settings) do
    case Vex.validate(struct, settings) do
      {:error, errors} ->
        normalized_errors = normalize_errors(errors, settings, struct.__struct__)
        {:error, {:validation_failed, normalized_errors}}

      other ->
        other
    end
  end

  def errors(struct, settings) do
    struct
    |> Vex.errors(settings)
    |> normalize_errors(settings, struct.__struct__)
  end

  def errors(struct) do
    settings = struct.__struct__.__vex_validations__()

    struct
    |> Vex.errors()
    |> normalize_errors(settings, struct.__struct__)
  end

  defp normalize_errors(errors, settings, struct_module) do
    Enum.reduce(errors, [], fn(error, acc) ->
      normalized_error = if Keyword.has_key?(struct_module.__info__(:functions), :normalize_error) do
        struct_module
        |> apply(:normalize_error, [error])
        |> normalize_error(settings)
      else
        normalize_error(error, settings)
      end

      acc ++ [normalized_error]
    end)
  end

  defp normalize_error({:error, key, :length, _}, settings) do
    info = Keyword.take(settings[key][:length], [:min, :max])
    {:error, key, {:invalid_length, info}}
  end

  defp normalize_error({:error, key, :acceptance, _}, _) do
    {:error, key, :must_be_true}
  end

  defp normalize_error({:error, key, :presence, _}, _) do
    {:error, key, :required}
  end

  defp normalize_error({:error, key, :format, _}, _) do
    {:error, key, :invalid_format}
  end

  defp normalize_error({:error, key, :uuid, _}, _) do
    {:error, key, :must_be_uuid}
  end

  defp normalize_error({:error, key, :inclusion, _}, _) do
    {:error, key, :invalid}
  end

  defp normalize_error({:error, key, :by, error_code}, _) do
    {:error, key, error_code}
  end

  defp normalize_error(tagged_error, _), do: tagged_error
end