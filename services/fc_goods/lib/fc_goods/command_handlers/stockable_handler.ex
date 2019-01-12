defmodule FCGoods.StockableHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCGoods.StockablePolicy

  alias FCGoods.{AddStockable}
  alias FCGoods.{StockableAdded}
  alias FCGoods.Stockable

  def handle(%Stockable{id: nil} = state, %AddStockable{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%StockableAdded{})
    |> unwrap_ok()
  end

  def handle(%Stockable{id: _}, %AddStockable{}) do
    {:error, {:already_exist, :app}}
  end

  def handle(%{id: nil}, _), do: {:error, {:not_found, :app}}
  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :app}}

  # def handle(state, %UpdateStockable{} = cmd) do
  #   cmd
  #   |> authorize(state)
  #   ~> merge_to(%StockableUpdated{})
  #   ~> put_original_fields(state)
  #   |> unwrap_ok()
  # end

  # def handle(state, %DeleteStockable{} = cmd) do
  #   cmd
  #   |> authorize(state)
  #   ~> merge_to(%StockableDeleted{})
  #   |> unwrap_ok()
  # end

  # defp put_original_fields(%{effective_keys: effective_keys} = event, state) do
  #   fields = Map.from_struct(state)

  #   original_fields =
  #     Enum.reduce(fields, %{}, fn({k, v}, acc) ->
  #       str_key = Atom.to_string(k)
  #       if Enum.member?(effective_keys, str_key) do
  #         Map.put(acc, str_key, v)
  #       else
  #         acc
  #       end
  #     end)

  #   Map.put(event, :original_fields, original_fields)
  # end
end