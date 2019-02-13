defmodule FCInventory.LineItemHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.LineItemPolicy

  alias FCInventory.{CreateLineItem, MarkLineItem}
  alias FCInventory.{LineItemCreated, LineItemMarked}
  alias FCInventory.LineItem

  def handle(%LineItem{id: nil} = state, %CreateLineItem{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%LineItemCreated{})
    |> unwrap_ok()
  end

  def handle(%LineItem{id: _}, %CreateLineItem{}) do
    {:error, {:already_exist, :line_item}}
  end

  def handle(%{id: nil}, _), do: {:error, {:not_found, :line_item}}
  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :line_item}}

  def handle(state, %MarkLineItem{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%LineItemMarked{original_status: state.status})
    |> unwrap_ok()
  end

  # def handle(state, %UpdateLineItem{} = cmd) do
  #   default_locale = FCStateStorage.GlobalStore.DefaultLocaleStore.get(state.account_id)
  #   translatable_fields = FCInventory.LineItem.translatable_fields()

  #   cmd
  #   |> authorize(state)
  #   ~> merge_to(%LineItemUpdated{})
  #   ~> put_translations(state, translatable_fields, default_locale)
  #   ~> put_original_fields(state)
  #   |> unwrap_ok()
  # end

  # def handle(state, %DeleteLineItem{} = cmd) do
  #   cmd
  #   |> authorize(state)
  #   ~> merge_to(%LineItemDeleted{})
  #   |> unwrap_ok()
  # end
end
