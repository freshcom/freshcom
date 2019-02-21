defmodule FCInventory.MovementTest do
  use FCInventory.UnitCase, async: true

  alias Decimal, as: D
  alias FCInventory.{
    MovementCreated,
    MovementMarked,
    LineItemAdded,
    LineItemMarked,
    LineItemUpdated,
    TransactionAdded
  }
  alias FCInventory.{Movement, LineItem}

  test "apply MovementCreated" do
    state = %Movement{}

    event = %MovementCreated{
      movement_id: uuid4()
    }

    assert state = Movement.apply(state, event)
    assert state.id == event.movement_id
  end

  describe "apply MovementMarked" do
    test "when status is processing" do
      line_item_id = uuid4()
      state = %Movement{
        line_items: %{line_item_id => %LineItem{}}
      }

      event = %MovementMarked{
        status: "processing"
      }

      assert state = Movement.apply(state, event)
      assert state.status == "processing"
      assert state.line_items[line_item_id].status == "processing"
    end

    test "when status is normal status" do
      line_item_id = uuid4()
      state = %Movement{
        line_items: %{line_item_id => %LineItem{}}
      }

      event = %MovementMarked{
        status: "reserved"
      }

      assert state = Movement.apply(state, event)
      assert state.status == "reserved"
      assert state.line_items[line_item_id].status == "pending"
    end
  end

  test "apply LineItemAdded" do
    state = %Movement{}

    event = %LineItemAdded{
      line_item_id: uuid4()
    }

    assert state = Movement.apply(state, event)
    assert map_size(state.line_items) == 1
  end

  test "apply LineItemMarked" do
    event = %LineItemMarked{
      line_item_id: uuid4(),
      status: "reserved"
    }

    state = %Movement{
      line_items: %{event.line_item_id => %LineItem{}}
    }

    assert state = Movement.apply(state, event)
    assert state.line_items[event.line_item_id].status == "reserved"
  end

  test "apply LineItemUpdated" do
    event = %LineItemUpdated{
      line_item_id: uuid4(),
      effective_keys: [:quantity, :translations],
      description: "Nothing here",
      quantity: D.new(5),
      translations: %{"zh-CN" => %{"description" => "Good"}}
    }

    state = %Movement{
      line_items: %{event.line_item_id => %LineItem{}}
    }

    assert %{line_items: line_items} = Movement.apply(state, event)
    assert line_item = line_items[event.line_item_id]
    assert line_items[event.line_item_id].quantity == event.quantity
    assert line_items[event.line_item_id].translations == event.translations
    assert line_items[event.line_item_id].description == nil
  end

  test "apply TransactionAdded" do
    event = %TransactionAdded{
      line_item_id: uuid4(),
      status: "reserved",
      quantity: D.new(5)
    }

    state = %Movement{
      line_items: %{event.line_item_id => %LineItem{}}
    }

    assert %{line_items: line_items} = Movement.apply(state, event)
    assert line_item = line_items[event.line_item_id]
    assert map_size(line_item.transactions) == 1
  end
end
