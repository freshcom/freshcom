defmodule FCInventory.Router.MarkLineItemTest do
  use FCBase.RouterCase

  alias FCInventory.Router
  alias FCInventory.MarkLineItem
  alias FCInventory.{LineItemMarked, LineItemCreated}

  setup do
    cmd = %MarkLineItem{
      line_item_id: uuid4(),
      status: "drafted"
    }

    %{cmd: cmd}
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%MarkLineItem{})
    assert length(errors) > 0
  end

  test "given non existing line item id", %{cmd: cmd} do
    assert {:error, {:not_found, :line_item}} = Router.dispatch(cmd)
  end

  test "given valid command with unauthorized role", %{cmd: cmd} do
    to_streams(:line_item_id, "stock-line-item-", [
      %LineItemCreated{
        client_id: uuid4(),
        account_id: uuid4(),
        requester_id: uuid4(),
        line_item_id: cmd.line_item_id
      }
    ])

    assert {:error, :access_denied} = Router.dispatch(cmd)
  end

  test "given valid command with authorized role", %{cmd: cmd} do
    account_id = uuid4()
    client_id = app_id("standard", account_id)
    requester_id = user_id(account_id, "goods_specialist")

    to_streams(:line_item_id, "stock-line-item-", [
      %LineItemCreated{
        client_id: client_id,
        account_id: account_id,
        requester_id: requester_id,
        line_item_id: cmd.line_item_id,
        status: "pending"
      }
    ])

    cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

    assert :ok = Router.dispatch(cmd)

    assert_receive_event(LineItemMarked, fn event ->
      assert event.status == cmd.status
      assert event.original_status == "pending"
    end)
  end

  test "given valid command with system role", %{cmd: cmd} do
    to_streams(:line_item_id, "stock-line-item-", [
      %LineItemCreated{
        line_item_id: cmd.line_item_id,
        status: "pending"
      }
    ])

    cmd = %{cmd | requester_role: "system"}

    assert :ok = Router.dispatch(cmd)

    assert_receive_event(LineItemMarked, fn event ->
      assert event.status == cmd.status
      assert event.original_status == "pending"
    end)
  end
end
