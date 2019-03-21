defmodule FCInventory.MovementHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.MovementPolicy

  alias Decimal, as: D
  alias FCInventory.{
    CreateMovement,
    MarkMovement
  }
  alias FCInventory.{
    MovementCreated,
    MovementMarked
  }
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

  def handle(state, %MarkMovement{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%MovementMarked{original_status: state.status})
    |> unwrap_ok()
  end

  defp mark_movement(%{} = event, state) do
    events = mark_movement([event], state)

    case length(events) do
      1 -> Enum.at(events, 0)
      _ -> events
    end
  end

  defp mark_movement(events, state) when is_list(events) do
    after_state =
      Enum.reduce(events, state, fn event, state ->
        Movement.apply(state, event)
      end)

    new_status = status(after_state)

    if after_state.status == new_status do
      events
    else
      movement_marked =
        %MovementMarked{requester_role: "system", movement_id: state.id}
        |> Map.put(:status, new_status)
        |> Map.put(:original_status, after_state.status)

      events ++ [movement_marked]
    end
  end

  defp mark_movement(event, _), do: event

  defp status(%{line_items: line_items}) do
    total = map_size(line_items)
    count =
      Enum.reduce(line_items, %{}, fn {_, line_item}, acc ->
        count = acc[line_item.status] || 0
        Map.put(acc, line_item.status, count + 1)
      end)

    cond do
      count["completed"] == total ->
        "completed"

      count["completing"] ->
        "completing"

      count["completed"] || count["partially_completed"] ->
        "partially_completed"

      count["packed"] == total ->
        "packed"

      count["packing"] ->
        "packing"

      count["packed"] || count["partially_packed"] ->
        "partially_packed"

      count["picked"] == total ->
        "picked"

      count["picking"] ->
        "picking"

      count["picked"] || count["partially_picked"] ->
        "partially_picked"

      count["reserved"] == total ->
        "reserved"

      count["reserving"] ->
        "reserving"

      count["reserved"] || count["partially_reserved"] ->
        "partially_reserved"

      count["none_reserved"] == total ->
        "none_reserved"

      true ->
        "pending"
    end
  end

  def line_item_status(%{status: current_status, quantity_processed: quantity, quantity: total}) do
    cond do
      quantity["completed"] && D.cmp(quantity["completed"], total) == :eq ->
        "completed"

      quantity["completing"] ->
        "completing"

      quantity["completed"] || quantity["partially_completed"] ->
        "partially_completed"

      quantity["packed"] && D.cmp(quantity["packed"], total) == :eq ->
        "packed"

      quantity["packing"] ->
        "packing"

      quantity["packed"] || quantity["partially_packed"] ->
        "partially_packed"

      quantity["picked"] && D.cmp(quantity["picked"], total) == :eq ->
        "picked"

      quantity["picked"] ->
        "picked"

      quantity["picked"] || quantity["partially_picked"] ->
        "partially_picked"

      quantity["reserved"] && D.cmp(quantity["reserved"], total) == :eq ->
        "reserved"

      quantity["reserving"] ->
        "reserving"

      quantity["reserved"] ->
        "partially_reserved"

      current_status == "pending" ->
        "pending"

      true ->
        "none_reserved"
    end
  end
end
