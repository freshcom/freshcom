defmodule FCIdentity.Validation do
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
        {:error, {:validation_failed, normalize_errors(errors, settings)}}

      other ->
        other
    end
  end

  def errors(struct, settings) do
    struct
    |> Vex.errors(settings)
    |> normalize_errors(settings)
  end

  def errors(struct) do
    settings = struct.__struct__.__vex_validations__()

    struct
    |> Vex.errors()
    |> normalize_errors(settings)
  end

  defp normalize_errors(errors, settings) do
    Enum.reduce(errors, [], fn(error, acc) ->
      acc ++ [normalize_error(error, settings)]
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
end