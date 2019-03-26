defmodule FCInventory.Router.DeleteTransactionTest do
  use FCBase.RouterCase

  import FCInventory.Fixture

  alias Decimal, as: D
  alias FCInventory.{AccountServiceMock, StaffServiceMock}
  alias FCInventory.{Account, Worker}
  alias FCInventory.Router
  alias FCInventory.DeleteTransaction
  alias FCInventory.{
    TransactionDeleted,
    TransactionPrepared,
    EntryAdded,
    EntryDeleted
  }

  setup do
    Application.ensure_all_started(:fc_inventory)
    :ok
  end

  test "dispatch invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%DeleteTransaction{})
    assert length(errors) > 0
  end

  test "dispatch command by unauthenticated account" do
    expect(AccountServiceMock, :find, fn(_) ->
      {:error, {:not_found, :account}}
    end)

    txn = draft_transaction("internal", "internal")
    cmd = %DeleteTransaction{
      account_id: txn.account_id,
      staff_id: uuid4(),
      transaction_id: txn.id
    }

    assert {:error, {:unauthenticated, :account}} = Router.dispatch(cmd)
  end

  describe "dispatch valid command for" do
    test "a draft transaction" do
      txn = draft_transaction("internal", "internal")
      cmd = %DeleteTransaction{
        staff_id: uuid4(),
        account_id: txn.account_id,
        transaction_id: txn.id
      }

      expect(AccountServiceMock, :find, fn(account_id) ->
        {:ok, %Account{id: account_id}}
      end)

      expect(StaffServiceMock, :find, fn(account, staff_id) ->
        assert account.id == cmd.account_id
        assert staff_id == cmd.staff_id

        {:ok, %Worker{account_id: account.id, id: staff_id}}
      end)

      assert :ok = Router.dispatch(cmd)

      assert_event(TransactionDeleted, fn event ->
        event.transaction_id == cmd.transaction_id
      end)
    end

    test "a prepared transaction" do
      txn = draft_transaction("internal", "internal", events: [
        %TransactionPrepared{
          status: "ready",
          quantity: D.new(5)
        }
      ])

      serial_number = serial_number(txn.account_id)
      add_entry(txn.account_id, stock_id(:src, txn), [
        %EntryAdded{
          serial_number: serial_number,
          status: "committed",
          quantity: D.new(2)
        },
        %EntryAdded{
          status: "committed",
          quantity: D.new(3)
        },
        %EntryAdded{
          transaction_id: txn.id,
          serial_number: serial_number,
          entry_id: "E1",
          status: "planned",
          quantity: D.new(-2)
        },
        %EntryAdded{
          transaction_id: txn.id,
          status: "planned",
          entry_id: "E2",
          quantity: D.new(-3)
        }
      ])

      add_entry(txn.account_id, stock_id(:dst, txn), [
        %EntryAdded{
          transaction_id: txn.id,
          serial_number: serial_number,
          entry_id: "E1",
          status: "planned",
          quantity: D.new(2)
        },
        %EntryAdded{
          transaction_id: txn.id,
          status: "planned",
          entry_id: "E2",
          quantity: D.new(3)
        }
      ])

      cmd = %DeleteTransaction{
        staff_id: uuid4(),
        account_id: txn.account_id,
        transaction_id: txn.id
      }

      expect(AccountServiceMock, :find, 4, fn(account_id) ->
        {:ok, %Account{id: account_id}}
      end)

      expect(StaffServiceMock, :find, fn(account, staff_id) ->
        assert account.id == cmd.account_id
        assert staff_id == cmd.staff_id

        {:ok, %Worker{account_id: account.id, id: staff_id}}
      end)

      assert :ok = Router.dispatch(cmd)

      assert_event(TransactionDeleted, fn event ->
        event.transaction_id == cmd.transaction_id
      end)

      assert_event(EntryDeleted, fn event ->
        event.entry_id == "E1" &&
        event.stock_id == stock_id(:src, txn)
      end)

      assert_event(EntryDeleted, fn event ->
        event.entry_id == "E1" &&
        event.stock_id == stock_id(:dst, txn)
      end)

      assert_event(EntryDeleted, fn event ->
        event.entry_id == "E2" &&
        event.stock_id == stock_id(:src, txn)
      end)

      assert_event(EntryDeleted, fn event ->
        event.entry_id == "E2" &&
        event.stock_id == stock_id(:dst, txn)
      end)
    end
  end
end
