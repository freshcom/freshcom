defmodule FCInventory.Movement do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias Decimal, as: D

  alias FCInventory.{
    MovementCreated,
    MovementMarked
  }

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :movement_id, String.t()

    field :cause_id, String.t()
    field :cause_type, String.t()
    field :source_id, String.t()
    field :destination_id, String.t()

    field :status, String.t(), default: "draft"

    field :name, String.t()
    field :number, String.t()
    field :label, String.t()
    field :expected_completion_date, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map(), default: %{}
    field :translations, map(), default: %{}
  end

  def translatable_fields do
    [
      :name,
      :caption,
      :description,
      :custom_data
    ]
  end

  def apply(state, %MovementCreated{} = event) do
    %{state | id: event.movement_id}
    |> merge(event)
  end

  def apply(state, %MovementMarked{} = event) do
    %{state | status: event.status}
  end
end
