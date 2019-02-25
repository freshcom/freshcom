defmodule FCInventory.MovementTest do
  use FCInventory.UnitCase, async: true

  alias Decimal, as: D
  alias FCInventory.{
    MovementCreated,
    MovementMarked,
    LineItemAdded,
    LineItemMarked,
    LineItemUpdated
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

  test "apply MovementMarked" do
    stockable_id = uuid4()
    state = %Movement{
      line_items: %{stockable_id => %LineItem{}}
    }

    event = %MovementMarked{
      status: "reserved"
    }

    assert state = Movement.apply(state, event)
    assert state.status == "reserved"
    assert state.line_items[stockable_id].status == "pending"
  end

  test "apply LineItemAdded" do
    state = %Movement{}

    event = %LineItemAdded{
      stockable_id: uuid4()
    }

    assert state = Movement.apply(state, event)
    assert map_size(state.line_items) == 1
  end

  test "apply LineItemMarked" do
    event = %LineItemMarked{
      stockable_id: uuid4(),
      status: "reserved"
    }

    state = %Movement{
      line_items: %{event.stockable_id => %LineItem{}}
    }

    assert state = Movement.apply(state, event)
    assert state.line_items[event.stockable_id].status == "reserved"
  end

  test "apply LineItemUpdated" do
    event = %LineItemUpdated{
      stockable_id: uuid4(),
      effective_keys: [:quantity, :translations],
      description: "Nothing here",
      quantity: D.new(5),
      translations: %{"zh-CN" => %{"description" => "Good"}}
    }

    state = %Movement{
      line_items: %{event.stockable_id => %LineItem{}}
    }

    assert %{line_items: line_items} = Movement.apply(state, event)
    assert line_item = line_items[event.stockable_id]
    assert line_items[event.stockable_id].quantity == event.quantity
    assert line_items[event.stockable_id].translations == event.translations
    assert line_items[event.stockable_id].description == nil
  end
end
