defmodule FCInventory.TransactionHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.TransactionPolicy

  alias FCInventory.{CreateTransaction}
  alias FCInventory.{TransactionCreated}
  alias FCInventory.Transaction

  def handle(%Transaction{id: nil} = state, %CreateTransaction{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%TransactionCreated{})
    |> unwrap_ok()
  end

  def handle(%Transaction{id: _}, %CreateTransaction{}) do
    {:error, {:already_exist, :transaction}}
  end

  def handle(%{id: nil}, _), do: {:error, {:not_found, :transaction}}
  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :transaction}}

  # def handle(state, %UpdateTransaction{} = cmd) do
  #   default_locale = FCStateStorage.GlobalStore.DefaultLocaleStore.get(state.account_id)
  #   translatable_fields = FCInventory.Transaction.translatable_fields()

  #   cmd
  #   |> authorize(state)
  #   ~> merge_to(%TransactionUpdated{})
  #   ~> put_translations(state, translatable_fields, default_locale)
  #   ~> put_original_fields(state)
  #   |> unwrap_ok()
  # end

  # def handle(state, %DeleteTransaction{} = cmd) do
  #   cmd
  #   |> authorize(state)
  #   ~> merge_to(%TransactionDeleted{})
  #   |> unwrap_ok()
  # end
end
