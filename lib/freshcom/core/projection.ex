defmodule Freshcom.Projection do
  defmacro __using__(_) do
    quote do
      use Ecto.Schema
      alias Ecto.UUID
      @primary_key {:id, :binary_id, autogenerate: false}
      @foreign_key_type :binary_id
    end
  end
end