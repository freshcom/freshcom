defmodule FCIdentity.App do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCIdentity.{AppAdded, AppDeleted}

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()

    field :status, String.t()
    field :type, String.t()
    field :name, String.t()
  end

  def apply(%{} = state, %AppAdded{} = event) do
    %{state | id: event.app_id}
    |> merge(event)
  end

  def apply(state, %AppDeleted{}) do
    %{state | status: "deleted"}
  end
end