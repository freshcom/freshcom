defmodule FCInventory.Router.RequestStockReservationTest do
  use FCBase.RouterCase

  alias FCInventory.{AccountServiceMock, StaffServiceMock}
  alias FCInventory.{Account, Worker}
  alias FCInventory.Router

  alias Decimal, as: D
  alias FCInventory.LineItem
  alias FCInventory.LocationStore
  alias FCInventory.RequestStockReservation
  alias FCInventory.{
    OrderCreated,
    StockReservationRequested,
    StockReservationFinished,
    StockReserved
  }

  setup do
    Application.ensure_all_started(:fc_inventory)

    cmd = %RequestStockReservation{
      account_id: uuid4(),
      staff_id: uuid4(),
      order_id: uuid4()
    }

    %{cmd: cmd}
  end

  test "dispatch invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%RequestStockReservation{})
    assert length(errors) > 0
  end

  test "dispatch command by unauthenticated account", %{cmd: cmd} do
    expect(AccountServiceMock, :find, fn(_) ->
      {:error, {:not_found, :account}}
    end)

    assert {:error, {:unauthenticated, :account}} = Router.dispatch(cmd)
  end

  describe "dispatch command by" do
    test "unauthenticated staff", %{cmd: cmd} do
      expect(AccountServiceMock, :find, fn(account_id) ->
        {:ok, %Account{id: account_id}}
      end)

      expect(StaffServiceMock, :find, fn(account, staff_id) ->
        assert account.id == cmd.account_id
        assert staff_id == cmd.staff_id

        {:error, {:not_found, :staff}}
      end)

      assert {:error, {:unauthenticated, :staff}} = Router.dispatch(cmd)
    end

    @tag :focus
    test "authorized staff", %{cmd: cmd} do
      expect(AccountServiceMock, :find, 6, fn(account_id) ->
        {:ok, %Account{id: account_id}}
      end)

      expect(StaffServiceMock, :find, fn(account, staff_id) ->
        assert account.id == cmd.account_id
        assert staff_id == cmd.staff_id

        {:ok, %Worker{account_id: account.id, id: staff_id}}
      end)

      location_id = uuid4()
      LocationStore.put(cmd.account_id, location_id, %{type: "partner"})

      to_streams(:order_id, "inventory-order-", [
        %OrderCreated{
          account_id: cmd.account_id,
          order_id: cmd.order_id,
          location_id: location_id,
          line_items: [
            %LineItem{sku: "SKU1", quantity: D.new(5)},
            %LineItem{sku: "SKU2", quantity: D.new(3)}
          ]
        }
      ])

      assert :ok = Router.dispatch(cmd)

      assert_receive_event(StockReservationRequested, fn event ->
        assert event.account_id == cmd.account_id
        assert event.staff_id == cmd.staff_id
      end)

      assert_event(StockReserved, fn event ->
        event.order_id == cmd.order_id &&
        event.stock_id.sku == "SKU1" &&
        D.cmp(event.quantity, D.new(5)) == :eq
      end)

      assert_event(StockReserved, fn event ->
        event.order_id == cmd.order_id &&
        event.stock_id.sku == "SKU2" &&
        D.cmp(event.quantity, D.new(3)) == :eq
      end)

      assert_event(StockReservationFinished, fn event ->
        event.order_id == cmd.order_id &&
        event.status == "reserved"
      end)
    end
  end
end
