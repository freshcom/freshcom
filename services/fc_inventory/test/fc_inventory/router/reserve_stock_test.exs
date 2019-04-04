defmodule FCInventory.Router.ReserveStockTest do
  use FCBase.RouterCase

  alias Decimal, as: D
  alias FCInventory.{AccountServiceMock, StaffServiceMock}
  alias FCInventory.{Account, Worker}
  alias FCInventory.Router

  alias FCInventory.LocationStore
  alias FCInventory.ReserveStock
  alias FCInventory.StockId
  alias FCInventory.{
    StockReserved,
    EntryAdded
  }

  setup do
    account_id = uuid4()
    location_id = uuid4()
    LocationStore.put(account_id, location_id, %{type: "partner"})

    cmd = %ReserveStock{
      account_id: account_id,
      staff_id: uuid4(),
      stock_id: %StockId{sku: uuid4(), location_id: location_id},
      order_id: uuid4(),
      quantity: D.new(5)
    }

    %{cmd: cmd}
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%ReserveStock{})
    assert length(errors) > 0
  end

  test "dispatch command by unauthenticated account", %{cmd: cmd} do
    expect(AccountServiceMock, :find, fn(_) ->
      {:error, {:not_found, :account}}
    end)

    assert {:error, {:unauthenticated, :account}} = Router.dispatch(cmd)
  end

  describe "dispatch command by" do
    setup do
      expect(AccountServiceMock, :find, fn(account_id) ->
        {:ok, %Account{id: account_id}}
      end)

      :ok
    end

    test "unauthenticated staff", %{cmd: cmd} do
      expect(StaffServiceMock, :find, fn(account, staff_id) ->
        assert account.id == cmd.account_id
        assert staff_id == cmd.staff_id

        {:error, {:not_found, :staff}}
      end)

      assert {:error, {:unauthenticated, :staff}} = Router.dispatch(cmd)
    end

    test "authorized staff", %{cmd: cmd} do
      expect(StaffServiceMock, :find, fn(account, staff_id) ->
        assert account.id == cmd.account_id
        assert staff_id == cmd.staff_id

        {:ok, %Worker{account_id: account.id, id: staff_id}}
      end)

      assert :ok = Router.dispatch(cmd)

      assert_event(EntryAdded, fn event ->
        D.cmp(event.quantity, D.minus(cmd.quantity))
      end)

      assert_event(StockReserved, fn event ->
        event.quantity == cmd.quantity
      end)
    end
  end

  # test "given valid command with authorized role", %{cmd: cmd} do
  #   assert :ok = Router.dispatch(cmd)

  #   assert_event(EntryAdded, fn event ->
  #     D.cmp(event.quantity, D.minus(cmd.quantity))
  #   end)

  #   assert_event(StockReserved, fn event ->
  #     event.quantity == cmd.quantity
  #   end)
  # end

  # test "given valid command with system role", %{cmd: cmd} do
  #   assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

  #   assert_event(EntryAdded, fn event ->
  #     D.cmp(event.quantity, D.minus(cmd.quantity))
  #   end)

  #   assert_event(StockReserved, fn event ->
  #     event.quantity == cmd.quantity
  #   end)
  # end
end
