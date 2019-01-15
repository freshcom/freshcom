defmodule Freshcom.Projection do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      alias Ecto.UUID
      @primary_key {:id, :binary_id, autogenerate: false}
      @foreign_key_type :binary_id
    end
  end

  def changeset(projection, event) do
    effective_keys = Enum.map(event.effective_keys, &String.to_existing_atom/1)
    changes = Map.take(event, effective_keys)
    Ecto.Changeset.change(projection, changes)
  end
end
