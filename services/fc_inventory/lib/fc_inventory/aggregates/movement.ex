defmodule FCInventory.Movement do
  @moduledoc false

  use TypedStruct
  use FCBase, :aggregate

  alias FCInventory.{
    MovementCreated,
    MovementMarked,
    TransactionAdded,
    LineItemAdded,
    LineItemMarked,
    LineItemUpdated
  }
  alias FCInventory.{LineItem, Transaction}

  typedstruct do
    field :id, String.t()
    field :account_id, String.t()
    field :movement_id, String.t()

    field :cause_id, String.t()
    field :cause_type, String.t()
    field :source_id, String.t()
    field :source_type, String.t()
    field :destination_id, String.t()
    field :destination_type, String.t()

    field :status, String.t(), default: "pending"
    field :number, String.t()
    field :label, String.t()
    field :expected_completion_date, DateTime.t()

    field :line_items, map(), default: %{}

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map(), default: %{}
    field :translations, map(), default: %{}
  end

  def translatable_fields do
    [
      :caption,
      :description,
      :custom_data
    ]
  end

  def apply(state, %MovementCreated{} = event) do
    %{state | id: event.movement_id}
    |> merge(event)
  end

  def apply(%{line_items: line_items} = state, %MovementMarked{status: "processing"}) do
    line_items =
      Enum.reduce(line_items, line_items, fn {id, line_item}, acc ->
        Map.put(acc, id, %{line_item | status: "processing"})
      end)

    %{
      state
      | line_items: line_items,
        status: "processing"
    }
  end

  def apply(state, %MovementMarked{} = event) do
    %{state | status: event.status}
  end

  def apply(state, %LineItemAdded{} = event) do
    line_item = merge(%LineItem{}, event)
    put_line_item(state, event.line_item_id, line_item)
  end

  def apply(state, %LineItemMarked{} = event) do
    line_item = %{
      state.line_items[event.line_item_id]
      | status: event.status
    }

    put_line_item(state, event.line_item_id, line_item)
  end

  def apply(state, %LineItemUpdated{} = event) do
    line_item =
      state.line_items[event.line_item_id]
      |> cast(event)
      |> apply_changes()

    put_line_item(state, event.line_item_id, line_item)
  end

  def apply(state, %TransactionAdded{} = event) do
    line_item = state.line_items[event.line_item_id]
    transaction = merge(%Transaction{}, event)
    transactions = Map.put(line_item.transactions, event.transaction_id, transaction)

    line_item = %{
      line_item
      | transactions: transactions
    }

    put_line_item(state, event.line_item_id, line_item)
  end

  defp put_line_item(state, id, line_item) do
    line_items = Map.put(state.line_items, id, line_item)
    %{state | line_items: line_items}
  end
end
