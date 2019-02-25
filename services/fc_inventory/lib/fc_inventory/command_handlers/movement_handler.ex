defmodule FCInventory.MovementHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  # @status_processing [
  #   "reserving",
  #   "picking",
  #   "packing",
  #   "delivering",
  #   "completing"
  # ]

  use FCBase, :command_handler

  import UUID
  import FCInventory.MovementPolicy

  alias Decimal, as: D
  alias FCStateStorage.GlobalStore.DefaultLocaleStore
  alias FCInventory.{
    CreateMovement,
    MarkMovement,
    UpdateLineItem,
    MarkLineItem,
    AddLineItem,
    ProcessLineItem
  }
  alias FCInventory.{
    MovementCreated,
    MovementMarked,
    LineItemAdded,
    LineItemProcessed,
    LineItemMarked,
    LineItemUpdated
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

  def handle(state, %MarkLineItem{} = cmd) do
    line_item = state.line_items[cmd.stockable_id]

    cmd
    |> authorize(state)
    ~>> ensure_line_item_exist(state)
    ~> merge_to(%LineItemMarked{original_status: line_item.status})
    ~> mark_movement(state)
    |> unwrap_ok()
  end

  def handle(state, %ProcessLineItem{} = cmd) do
    line_item = state.line_items[cmd.stockable_id]

    cmd
    |> authorize(state)
    ~>> ensure_line_item_exist(state)
    ~> merge_to(%LineItemProcessed{})
    ~> mark_line_item(state)
    |> unwrap_ok()
  end

  def handle(state, %AddLineItem{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%LineItemAdded{})
    ~> mark_movement(state)
    |> unwrap_ok()
  end

  def handle(state, %UpdateLineItem{} = cmd) do
    default_locale = DefaultLocaleStore.get(state.account_id)
    translatable_fields = FCInventory.LineItem.translatable_fields()
    line_item = state.line_items[cmd.stockable_id]

    cmd
    |> authorize(state)
    ~>> ensure_line_item_exist(state)
    ~> merge_to(%LineItemUpdated{})
    ~> put_translations(line_item, translatable_fields, default_locale)
    ~> put_original_fields(line_item)
    ~> mark_line_item(state)
    |> unwrap_ok()
  end

  defp mark_line_item(event, state) do
    line_item =
      state
      |> Movement.apply(event)
      |> Map.get(:line_items)
      |> Map.get(event.stockable_id)

    new_status = line_item_status(line_item)

    if line_item.status == new_status do
      event
    else
      line_item_marked =
        %LineItemMarked{}
        |> merge(event)
        |> Map.put(:status, new_status)
        |> Map.put(:original_status, line_item.status)

      mark_movement([event, line_item_marked], state)
    end
  end

  defp mark_movement(%LineItemAdded{status: "pending"} = event, %{status: m_status}) when m_status != "pending" do
    movement_marked =
      %MovementMarked{}
      |> merge(event)
      |> Map.put(:status, "pending")
      |> Map.put(:original_status, m_status)

    [event, movement_marked]
  end

  defp mark_movement(%LineItemUpdated{} = event, %{status: m_status}) when m_status != "pending" do
    movement_marked =
      %MovementMarked{}
      |> merge(event)
      |> Map.put(:status, "pending")
      |> Map.put(:original_status, m_status)

    [event, movement_marked]
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

  def line_item_status(%{quantity_processed: quantity, quantity: total}) do
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

      true ->
        "pending"
    end
  end

  defp ensure_line_item_exist(%{stockable_id: stockable_id} = cmd, state) do
    if state.line_items[stockable_id] do
      {:ok, cmd}
    else
      {:error, {:not_found, :line_item}}
    end
  end

  # defp balance_transaction(%LineItemUpdated{effective_keys: ekeys} = event, line_item) do
  #   if Enum.member?(ekeys, :quantity) do
  #     events = [event] ++ balance_transaction(line_item, event.quantity)
  #     unwrap_event(events)
  #   else
  #     event
  #   end
  # end

  # defp balance_transaction(%LineItem{quantity: current_quantity} = li, target_quantity) do
  #   if D.cmp(target_quantity, current_quantity) == :lt do
  #     decrease = D.sub(current_quantity, target_quantity)
  #     transactions = Enum.into(transactions, [])
  #     decrease_transaction(transactions, decrease, [])
  #   else
  #     []
  #   end
  # end

  # defp decrease_transaction([{id, txn} | transactions], decrease, events) do
  #   case D.cmp(txn.quantity, decrease) do
  #     :eq ->
  #       events = %TransactionCanceled{
  #         account_id: txn.account_id
  #         movement_id: txn.movement_id
  #       }
  #       events ++ [%TransactionCanceled{}]
  #   end
  # end

  defp unwrap_event([event]), do: event
  defp unwrap_event(events), do: events
end
