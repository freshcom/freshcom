defmodule FCIdentity.UnitCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import UUID
      import FCIdentity.UnitCase
    end
  end

  def has_error(errors, target_key, target_reason) do
    Enum.any?(errors, fn(error) ->
      {:error, key, reason} = error
      key == target_key && reason == target_reason
    end)
  end
end