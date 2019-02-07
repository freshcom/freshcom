defmodule FCInventory.BatchHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.BatchPolicy

  alias FCInventory.{AddBatch, UpdateBatch, DeleteBatch}
  alias FCInventory.{BatchAdded, BatchUpdated, BatchDeleted}
  alias FCInventory.Batch

  def handle(%Batch{id: nil} = state, %AddBatch{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%BatchAdded{quantity_available: quantity_available(cmd)})
    |> unwrap_ok()
  end

  def handle(%Batch{id: _}, %AddBatch{}) do
    {:error, {:already_exist, :batch}}
  end

  def handle(%{id: nil}, _), do: {:error, {:not_found, :batch}}
  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :batch}}

  def handle(state, %UpdateBatch{} = cmd) do
    default_locale = FCStateStorage.GlobalStore.DefaultLocaleStore.get(state.account_id)
    translatable_fields = FCInventory.Batch.translatable_fields()

    cmd
    |> authorize(state)
    ~> merge_to(%BatchUpdated{})
    ~> put_translations(state, translatable_fields, default_locale)
    ~> put_original_fields(state)
    |> unwrap_ok()
  end

  def handle(state, %DeleteBatch{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%BatchDeleted{})
    |> unwrap_ok()
  end

  defp quantity_available(%{quantity_on_hand: qoh, expires_at: nil}), do: qoh

  defp quantity_available(%{quantity_on_hand: qoh, expires_at: expires_at}) do
    if Timex.before?(Timex.now(), expires_at) do
      qoh
    else
      0
    end
  end
end