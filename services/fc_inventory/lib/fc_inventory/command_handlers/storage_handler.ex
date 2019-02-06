defmodule FCInventory.StorageHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.StoragePolicy

  alias FCInventory.{AddStorage, UpdateStorage, DeleteStorage}
  alias FCInventory.{StorageAdded, StorageUpdated, StorageDeleted}
  alias FCInventory.Storage

  def handle(%Storage{id: nil} = state, %AddStorage{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%StorageAdded{})
    |> unwrap_ok()
  end

  def handle(%Storage{id: _}, %AddStorage{}) do
    {:error, {:already_exist, :storage}}
  end

  def handle(%{id: nil}, _), do: {:error, {:not_found, :storage}}
  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :storage}}

  def handle(state, %UpdateStorage{} = cmd) do
    default_locale = FCStateStorage.GlobalStore.DefaultLocaleStore.get(state.account_id)
    translatable_fields = FCInventory.Storage.translatable_fields()

    cmd
    |> authorize(state)
    ~> merge_to(%StorageUpdated{})
    ~> put_translations(state, translatable_fields, default_locale)
    ~> put_original_fields(state)
    |> unwrap_ok()
  end

  def handle(state, %DeleteStorage{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%StorageDeleted{})
    |> unwrap_ok()
  end
end
