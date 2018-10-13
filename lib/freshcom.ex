defmodule Freshcom do
  def projector do
    quote do
      alias Ecto.{Changeset, Multi}
    end
  end

  def projection do
    quote do
      use Ecto.Schema
      alias Ecto.UUID
      @primary_key {:id, :binary_id, autogenerate: false}
      @foreign_key_type :binary_id
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end