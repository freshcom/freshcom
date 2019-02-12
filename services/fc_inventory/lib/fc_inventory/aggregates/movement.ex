defmodule FCInventory.Movement do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCInventory.{MovementCreated}

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :movement_id, String.t()

    field :cause_id, String.t()
    field :cause_type, String.t()
    field :source_id, String.t()
    field :source_type, String.t()
    field :destination_id, String.t()
    field :destination_type, String.t()

    field :status, String.t()
    field :number, String.t()
    field :label, String.t()
    field :expected_completion_date, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
    field :translations, map()
  end

  def translatable_fields do
    [
      :caption,
      :description,
      :custom_data
    ]
  end

  def apply(%{} = state, %MovementCreated{} = event) do
    %{state | id: event.movement_id}
    |> merge(event)
  end

  # def apply(state, %MovementUpdated{} = event) do
  #   state
  #   |> cast(event)
  #   |> apply_changes()
  # end

  # def apply(state, %MovementDeleted{}) do
  #   %{state | status: "deleted"}
  # end
end
