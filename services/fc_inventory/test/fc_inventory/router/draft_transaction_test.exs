defmodule FCInventory.Router.DraftTransactionTest do
  use FCBase.RouterCase

  alias FCInventory.{AccountServiceMock, StaffServiceMock}
  alias FCInventory.{Account, Worker}
  alias FCInventory.Router
  alias FCInventory.DraftTransaction
  alias FCInventory.TransactionDrafted

  setup do
    cmd = %DraftTransaction{
      account_id: uuid4(),
      staff_id: uuid4(),
      sku_id: uuid4(),
      source_id: uuid4(),
      destination_id: uuid4(),
      quantity: Decimal.new(5)
    }

    %{cmd: cmd}
  end

  test "dispatch invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%DraftTransaction{})
    assert length(errors) > 0
  end

  test "dispatch command with unauthenticated account", %{cmd: cmd} do
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

      assert_receive_event(TransactionDrafted, fn event ->
        assert event.account_id == cmd.account_id
        assert event.staff_id == cmd.staff_id
        assert event.sku_id == cmd.sku_id
        assert event.source_id == cmd.source_id
        assert event.destination_id == cmd.destination_id
        assert event.quantity == cmd.quantity
      end)
    end
  end
end
