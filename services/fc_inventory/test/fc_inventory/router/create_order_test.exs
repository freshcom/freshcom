defmodule FCInventory.Router.CreateOrderTest do
  use FCBase.RouterCase

  alias FCInventory.{AccountServiceMock, StaffServiceMock}
  alias FCInventory.{Account, Associate}
  alias FCInventory.Router

  alias FCInventory.CreateOrder
  alias FCInventory.OrderCreated

  setup do
    cmd = %CreateOrder{
      account_id: uuid4(),
      staff_id: uuid4(),
      location_id: uuid4()
    }

    %{cmd: cmd}
  end

  test "dispatch invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%CreateOrder{})
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

        {:ok, %Associate{account_id: account.id, id: staff_id}}
      end)

      assert :ok = Router.dispatch(cmd)

      assert_receive_event(OrderCreated, fn event ->
        assert event.account_id == cmd.account_id
        assert event.staff_id == cmd.staff_id
      end)
    end
  end
end
