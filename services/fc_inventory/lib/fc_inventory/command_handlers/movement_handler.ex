defmodule FCInventory.MovementHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import UUID
  import FCInventory.MovementPolicy

  alias Decimal, as: D
  alias FCStateStorage.GlobalStore.DefaultLocaleStore
  alias FCInventory.{
    CreateMovement,
    MarkMovement,
    MarkLineItem,
    AddLineItem,
    UpdateLineItem,
    AddTransaction
  }
  alias FCInventory.{
    MovementCreated,
    MovementMarked,
    LineItemAdded,
    LineItemMarked,
    LineItemUpdated,
    TransactionAdded
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

  def handle(state, %AddLineItem{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%LineItemAdded{line_item_id: uuid4()})
    ~> process_movement(state)
    |> unwrap_ok()
  end

  def handle(state, %UpdateLineItem{} = cmd) do
    default_locale = DefaultLocaleStore.get(state.account_id)
    translatable_fields = FCInventory.LineItem.translatable_fields()
    line_item = state.line_items[cmd.line_item_id]

    cmd
    |> authorize(state)
    ~>> ensure_line_item_exist(state)
    ~> merge_to(%LineItemUpdated{})
    ~> put_translations(line_item, translatable_fields, default_locale)
    ~> put_original_fields(line_item)
    ~> process_movement(state)
    |> unwrap_ok()
  end

  def handle(state, %MarkLineItem{status: "processed"} = cmd) do
    line_item = state.line_items[cmd.line_item_id]
    cmd = %{cmd | status: line_item_status(line_item)}
    handle(state, cmd)
  end

  def handle(state, %MarkLineItem{} = cmd) do
    line_item = state.line_items[cmd.line_item_id]

    cmd
    |> authorize(state)
    ~>> ensure_line_item_exist(state)
    ~> merge_to(%LineItemMarked{original_status: line_item.status})
    ~> process_movement(state)
    |> unwrap_ok()
  end

  def handle(state, %AddTransaction{} = cmd) do
    cmd
    |> authorize(state)
    ~>> ensure_line_item_exist(state)
    ~> merge_to(%TransactionAdded{})
    ~> process_line_item(state)
    |> unwrap_ok()
  end

  defp process_line_item(%TransactionAdded{} = event, %{status: "processing"}), do: event

  defp process_line_item(%TransactionAdded{} = event, state) do
    current_status = state.line_items[event.line_item_id].status
    next_status =
      state
      |> Movement.apply(event)
      |> Map.get(:line_items)
      |> Map.get(event.line_item_id)
      |> line_item_status()

    if next_status == current_status do
      event
    else
      line_item_marked =
        %LineItemMarked{}
        |> merge(event)
        |> Map.put(:status, next_status)
        |> Map.put(:original_status, current_status)

      process_movement([event, line_item_marked], state)
    end
  end

  defp process_movement(%LineItemAdded{status: "pending"} = event, %{status: m_status}) when m_status != "pending" do
    movement_marked =
      %MovementMarked{}
      |> merge(event)
      |> Map.put(:status, "pending")
      |> Map.put(:original_status, m_status)

    [event, movement_marked]
  end

  defp process_movement(%LineItemUpdated{} = event, %{status: m_status}) when m_status != "pending" do
    movement_marked =
      %MovementMarked{}
      |> merge(event)
      |> Map.put(:status, "pending")
      |> Map.put(:original_status, m_status)

    [event, movement_marked]
  end

  defp process_movement(%{} = event, state) do
    events = process_movement([event], state)

    case length(events) do
      1 -> Enum.at(events, 0)
      _ -> events
    end
  end

  defp process_movement(events, state) when is_list(events) do
    after_state =
      Enum.reduce(events, state, fn event, state ->
        Movement.apply(state, event)
      end)

    after_state_status = status(after_state)
    if after_state_status == state.status do
      events
    else
      movement_marked =
        %MovementMarked{requester_role: "system", movement_id: state.id}
        |> Map.put(:status, after_state_status)
        |> Map.put(:original_status, state.status)

      events ++ [movement_marked]
    end
  end

  defp process_movement(event, _), do: event

  defp status(%{line_items: line_items}) do
    total = map_size(line_items)
    count =
      Enum.reduce(line_items, %{}, fn {_, line_item}, acc ->
        count = acc[line_item.status] || 0
        Map.put(acc, line_item.status, count + 1)
      end)

    cond do
      count["processing"] ->
        "processing"

      count["pending"] ->
        "pending"

      count["completed"] == total ->
        "completed"

      count["completed"] || count["partially_completed"] ->
        "partially_completed"

      count["packed"] == total ->
        "packed"

      count["packed"] || count["partially_packed"] ->
        "partially_packed"

      count["picked"] == total ->
        "picked"

      count["picked"] || count["partially_picked"] ->
        "partially_picked"

      count["reserved"] == total ->
        "reserved"

      count["reserved"] || count["partially_reserved"] ->
        "partially_reserved"

      count["none_reserved"] == total ->
        "none_reserved"
    end
  end

  def line_item_status(%{quantity: total, transactions: transactions}) do
    quantity =
      Enum.reduce(transactions, %{}, fn {_, transaction}, acc ->
        quantity = acc[transaction.status] || D.new(0)
        Map.put(acc, transaction.status, D.add(quantity, transaction.quantity))
      end)

    cond do
      quantity["completed"] && D.cmp(quantity["completed"], total) == :eq ->
        "completed"

      quantity["completed"] || quantity["partially_completed"] ->
        "partially_completed"

      quantity["packed"] && D.cmp(quantity["packed"], total) == :eq ->
        "packed"

      quantity["packed"] || quantity["partially_packed"] ->
        "partially_packed"

      quantity["picked"] && D.cmp(quantity["picked"], total) == :eq ->
        "picked"

      quantity["picked"] || quantity["partially_picked"] ->
        "partially_picked"

      quantity["reserved"] && D.cmp(quantity["reserved"], total) == :eq ->
        "reserved"

      quantity["reserved"] ->
        "partially_reserved"

      true ->
        "none_reserved"
    end

  end

  defp ensure_line_item_exist(%{line_item_id: line_item_id} = cmd, state) do
    if state.line_items[line_item_id] do
      {:ok, cmd}
    else
      {:error, {:not_found, :line_item}}
    end
  end
end
