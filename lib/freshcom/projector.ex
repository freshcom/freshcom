defmodule Freshcom.Projector do
  defmacro __using__(_) do
    quote do
      alias Ecto.{Changeset, Multi}
    end
  end
end