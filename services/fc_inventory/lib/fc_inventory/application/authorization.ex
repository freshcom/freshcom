defmodule FCInventory.Authorization do
  def authorize(cmd, type) do
    case type.from(cmd._staff_) do
      nil -> {:error, {:unauthorized, :staff}}
      staff -> {:ok, %{cmd | _staff_: staff}}
    end
  end
end