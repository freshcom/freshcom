defmodule FCInventory.MovementHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.MovementPolicy

  alias FCInventory.{CreateMovement}
  alias FCInventory.{MovementCreated}
  alias FCInventory.Movement

  def handle(%Movement{id: nil} = state, %CreateMovement{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%MovementCreated{})
    |> unwrap_ok()
  end

  def handle(%Movement{id: _}, %CreateMovement{}) do
    {:error, {:already_exist, :movement}}
  end

  def handle(%{id: nil}, _), do: {:error, {:not_found, :movement}}
  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :movement}}

  # def handle(state, %UpdateMovement{} = cmd) do
  #   default_locale = FCStateStorage.GlobalStore.DefaultLocaleStore.get(state.account_id)
  #   translatable_fields = FCInventory.Movement.translatable_fields()

  #   cmd
  #   |> authorize(state)
  #   ~> merge_to(%MovementUpdated{})
  #   ~> put_translations(state, translatable_fields, default_locale)
  #   ~> put_original_fields(state)
  #   |> unwrap_ok()
  # end

  # def handle(state, %DeleteMovement{} = cmd) do
  #   cmd
  #   |> authorize(state)
  #   ~> merge_to(%MovementDeleted{})
  #   |> unwrap_ok()
  # end
end
