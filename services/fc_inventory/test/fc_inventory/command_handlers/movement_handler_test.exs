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

  # describe "handle CreateMovement" do
  #   test "when command is not authorized" do
  #     cmd = %CreateMovement{}
  #     state = %Movement{}

  #     assert {:error, :access_denied} = MovementHandler.handle(state, cmd)
  #   end

  #   test "when command is valid" do
  #     cmd = %CreateMovement{
  #       requester_role: "system",
  #       account_id: uuid4(),
  #       movement_id: uuid4()
  #     }
  #     state = %Movement{}

  #     assert event = MovementHandler.handle(state, cmd)
  #     assert %MovementCreated{} = event
  #     assert event.requester_role == cmd.requester_role
  #     assert event.account_id == cmd.account_id
  #     assert event.movement_id == cmd.movement_id
  #   end
  # end

  # describe "handle MarkMovement" do
  #   test "when command is not authorized" do
  #     cmd = %MarkMovement{}
  #     state = %Movement{id: uuid4()}

  #     assert {:error, :access_denied} = MovementHandler.handle(state, cmd)
  #   end

  #   test "when command is valid" do
  #     cmd = %MarkMovement{
  #       requester_role: "system",
  #       account_id: uuid4(),
  #       movement_id: uuid4(),
  #       status: "reserving"
  #     }
  #     state = %Movement{
  #       id: cmd.movement_id,
  #       status: "pending"
  #     }

  #     assert event = MovementHandler.handle(state, cmd)
  #     assert %MovementMarked{} = event
  #     assert event.requester_role == cmd.requester_role
  #     assert event.account_id == cmd.account_id
  #     assert event.movement_id == cmd.movement_id
  #     assert event.status == cmd.status
  #     assert event.original_status == state.status
  #   end
  # end
end
