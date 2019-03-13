defmodule FCInventory.Router.ReserveStockTest do
  use FCBase.RouterCase

  alias Decimal, as: D
  alias FCInventory.Router
  alias FCInventory.LocationStore
  alias FCInventory.ReserveStock
  alias FCInventory.{
    StockReserved,
    EntryAdded
  }

  setup do
    account_id = uuid4()
    location_id = uuid4()
    stockable_id = uuid4()
    LocationStore.put(account_id, location_id, %{type: "partner"})

    cmd = %ReserveStock{
      account_id: account_id,
      stock_id: "#{stockable_id}/#{location_id}",
      quantity: D.new(5)
    }

    %{cmd: cmd}
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%ReserveStock{})
    assert length(errors) > 0
  end

  test "given valid command with unauthorized role", %{cmd: cmd} do
    assert {:error, :access_denied} = Router.dispatch(cmd)
  end

  test "given valid command with authorized role", %{cmd: cmd} do
    requester_id = user_id(cmd.account_id, "goods_specialist")
    client_id = app_id("standard", cmd.account_id)

    cmd = %{cmd | client_id: client_id, requester_id: requester_id}

    assert :ok = Router.dispatch(cmd)

    assert_event(EntryAdded, fn event ->
      D.cmp(event.quantity, D.minus(cmd.quantity))
    end)

    assert_event(StockReserved, fn event ->
      event.quantity == cmd.quantity
    end)
  end

  test "given valid command with system role", %{cmd: cmd} do
    assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

    assert_event(EntryAdded, fn event ->
      D.cmp(event.quantity, D.minus(cmd.quantity))
    end)

    assert_event(StockReserved, fn event ->
      event.quantity == cmd.quantity
    end)
  end
end
