defmodule FCInventory.MovementHandlerTest do
  use FCInventory.UnitCase, async: true

  alias Decimal, as: D
  alias FCInventory.{
    CreateMovement,
    MarkMovement,
    AddLineItem,
    MarkLineItem,
    UpdateLineItem
  }
  alias FCInventory.{
    MovementCreated,
    MovementMarked,
    LineItemMarked,
    LineItemAdded,
    LineItemUpdated
  }
  alias FCInventory.MovementHandler
  alias FCInventory.{Movement, LineItem}

  setup do
    state = %Movement{id: uuid4(), account_id: uuid4()}

    %{state: state}
  end

  describe "handle CreateMovement" do
    test "when command is not authorized" do
      cmd = %CreateMovement{}
      state = %Movement{}

      assert {:error, :access_denied} = MovementHandler.handle(state, cmd)
    end

    test "when command is valid" do
      cmd = %CreateMovement{
        requester_role: "system",
        account_id: uuid4(),
        movement_id: uuid4()
      }
      state = %Movement{}

      assert event = MovementHandler.handle(state, cmd)
      assert %MovementCreated{} = event
      assert event.requester_role == cmd.requester_role
      assert event.account_id == cmd.account_id
      assert event.movement_id == cmd.movement_id
    end
  end

  describe "handle MarkMovement" do
    test "when command is not authorized" do
      cmd = %MarkMovement{}
      state = %Movement{id: uuid4()}

      assert {:error, :access_denied} = MovementHandler.handle(state, cmd)
    end

    test "when command is valid" do
      cmd = %MarkMovement{
        requester_role: "system",
        account_id: uuid4(),
        movement_id: uuid4(),
        status: "reserving"
      }
      state = %Movement{
        id: cmd.movement_id,
        status: "pending"
      }

      assert event = MovementHandler.handle(state, cmd)
      assert %MovementMarked{} = event
      assert event.requester_role == cmd.requester_role
      assert event.account_id == cmd.account_id
      assert event.movement_id == cmd.movement_id
      assert event.status == cmd.status
      assert event.original_status == state.status
    end
  end

  describe "handle AddLineItem" do
    test "when movement id is nil" do
      cmd = %AddLineItem{}
      state = %Movement{}

      assert {:error, {:not_found, :movement}} = MovementHandler.handle(state, cmd)
    end

    test "when command is not authorized" do
      cmd = %AddLineItem{}
      state = %Movement{id: uuid4()}

      assert {:error, :access_denied} = MovementHandler.handle(state, cmd)
    end

    test "when command is valid" do
      cmd = %AddLineItem{
        requester_role: "system",
        account_id: uuid4(),
        movement_id: uuid4(),
        stockable_id: uuid4(),
        quantity: D.new(5)
      }
      state = %Movement{
        id: cmd.movement_id,
        status: "pending"
      }

      assert event = MovementHandler.handle(state, cmd)
      assert %LineItemAdded{} = event
      assert event.requester_role == cmd.requester_role
      assert event.account_id == cmd.account_id
      assert event.movement_id == cmd.movement_id
      assert event.stockable_id == cmd.stockable_id
      assert event.quantity == cmd.quantity
    end

    test "when command changes movement status" do
      cmd = %AddLineItem{
        requester_role: "system",
        account_id: uuid4(),
        movement_id: uuid4(),
        stockable_id: uuid4(),
        quantity: D.new(5)
      }
      state = %Movement{
        id: cmd.movement_id,
        status: "reserved"
      }

      assert events = MovementHandler.handle(state, cmd)
      assert [%LineItemAdded{} = li_added | events] = events
      assert [%MovementMarked{} = m_marked | events] = events

      assert li_added.requester_role == cmd.requester_role
      assert li_added.account_id == cmd.account_id
      assert li_added.movement_id == cmd.movement_id
      assert li_added.stockable_id == cmd.stockable_id
      assert li_added.quantity == cmd.quantity

      assert m_marked.requester_role == cmd.requester_role
      assert m_marked.account_id == cmd.account_id
      assert m_marked.movement_id == cmd.movement_id
      assert m_marked.status == "pending"
    end
  end

  describe "handle UpdateLineItem" do
    test "when movement id is nil" do
      cmd = %UpdateLineItem{}
      state = %Movement{}

      assert {:error, {:not_found, :movement}} = MovementHandler.handle(state, cmd)
    end

    test "when command is not authorized" do
      cmd = %UpdateLineItem{}
      state = %Movement{id: uuid4()}

      assert {:error, :access_denied} = MovementHandler.handle(state, cmd)
    end

    test "when line item does not exist in state" do
      cmd = %UpdateLineItem{
        requester_role: "system",
        stockable_id: uuid4()
      }
      state = %Movement{id: uuid4()}

      assert {:error, {:not_found, :line_item}} = MovementHandler.handle(state, cmd)
    end

    test "when command is valid" do
      cmd = %UpdateLineItem{
        requester_role: "system",
        stockable_id: uuid4(),
        locale: "zh-CN",
        effective_keys: [:quantity, :description],
        quantity: D.new(5),
        description: "zh-CN description"
      }
      state = %Movement{
        id: uuid4(),
        status: "none_reserved",
        line_items: %{
          cmd.stockable_id => %LineItem{status: "none_reserved", quantity: D.new(2)}
        }
      }

      assert event = MovementHandler.handle(state, cmd)
      assert %LineItemUpdated{} = event
      assert event.translations["zh-CN"]["description"] == cmd.description
      assert event.quantity == cmd.quantity
      assert event.effective_keys == [:quantity, :translations]
      assert event.original_fields[:quantity] == state.line_items[cmd.stockable_id].quantity
    end
  end

  describe "handle MarkLineItem" do
    test "when movement id is nil" do
      cmd = %MarkLineItem{}
      state = %Movement{}

      assert {:error, {:not_found, :movement}} = MovementHandler.handle(state, cmd)
    end

    test "when command is not authorized" do
      cmd = %MarkLineItem{}
      state = %Movement{id: uuid4()}

      assert {:error, :access_denied} = MovementHandler.handle(state, cmd)
    end

    test "when line item does not exist in state" do
      cmd = %MarkLineItem{
        requester_role: "system",
        stockable_id: uuid4()
      }
      state = %Movement{id: uuid4()}

      assert {:error, {:not_found, :line_item}} = MovementHandler.handle(state, cmd)
    end

    test "when command is valid" do
      cmd = %MarkLineItem{
        requester_role: "system",
        stockable_id: uuid4(),
        status: "reserving"
      }
      state = %Movement{
        id: uuid4(),
        status: "reserving",
        line_items: %{
          cmd.stockable_id => %LineItem{quantity: D.new(2)}
        }
      }

      assert event = MovementHandler.handle(state, cmd)
      assert %LineItemMarked{} = event
      assert event.stockable_id == cmd.stockable_id
      assert event.status == "reserving"
      assert event.original_status == "pending"
    end

    test "when command also changes movement status" do
      cmd = %MarkLineItem{
        requester_role: "system",
        stockable_id: uuid4(),
        status: "reserving"
      }
      state = %Movement{
        id: uuid4(),
        line_items: %{
          cmd.stockable_id => %LineItem{quantity: D.new(2)}
        }
      }

      assert events = MovementHandler.handle(state, cmd)
      assert [%LineItemMarked{} = li_marked | events] = events
      assert [%MovementMarked{} = m_marked] = events
      assert li_marked.stockable_id == cmd.stockable_id
      assert li_marked.status == "reserving"
      assert li_marked.original_status == "pending"
      assert m_marked.status == "reserving"
      assert m_marked.original_status == "pending"
    end
  end
end
