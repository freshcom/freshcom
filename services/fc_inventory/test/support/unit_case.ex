defmodule FCInventory.UnitCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import UUID
      import FCInventory.UnitCase
    end
  end

  def has_error(errors, target_key, target_reason) do
    Enum.any?(errors, fn error ->
      case error do
        {:error, key, {reason, _}} ->
          key == target_key && reason == target_reason

        {:error, key, reason} ->
          key == target_key && reason == target_reason

        _ ->
          false
      end
    end)
  end
end
