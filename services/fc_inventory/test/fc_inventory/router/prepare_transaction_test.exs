defmodule FCInventory.Router.PrepareTransactionTest do
  use FCBase.RouterCase

  import FCInventory.Fixture

  alias FCInventory.{AccountServiceMock, StaffServiceMock}
  alias FCInventory.{Account, Worker}
  alias Decimal, as: D
  alias FCInventory.Router
  alias FCInventory.PrepareTransaction
  alias FCInventory.{
    EntryAdded,
    EntryUpdated,
    EntryDeleted,
    TransactionUpdated,
    TransactionPrepRequested,
    TransactionPrepared,
    TransactionPrepFailed
  }

  setup do
    Application.ensure_all_started(:fc_inventory)

    :ok
  end

  test "dispatch invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%PrepareTransaction{})
    assert length(errors) > 0
  end

  test "dispatch command with unauthenticated account" do
    expect(AccountServiceMock, :find, fn(_) ->
      {:error, {:not_found, :account}}
    end)

    cmd = %PrepareTransaction{
      account_id: uuid4(),
      staff_id: uuid4(),
      transaction_id: uuid4()
    }

    assert {:error, {:unauthenticated, :account}} = Router.dispatch(cmd)
  end

  describe "dispatch command by" do
    setup do
      txn = draft_transaction("partner", "internal")

      cmd = %PrepareTransaction{
        account_id: txn.account_id,
        staff_id: uuid4(),
        transaction_id: txn.id
      }

      %{cmd: cmd}
    end

    test "unauthorized staff", %{cmd: cmd} do
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

    test "authorized staff", %{cmd: cmd} do
      expect(AccountServiceMock, :find, 2, fn(account_id) ->
        {:ok, %Account{id: account_id}}
      end)

      expect(StaffServiceMock, :find, 1, fn(account, staff_id) ->
        assert account.id == cmd.account_id
        assert staff_id == cmd.staff_id

        {:ok, %Worker{account_id: account.id, id: staff_id}}
      end)

      assert :ok = Router.dispatch(cmd)

      assert_event(TransactionPrepared, fn event ->
        event.transaction_id == cmd.transaction_id
      end)
    end
  end

  describe "dispatch command for transaction that was never prepared before and" do
    setup do
      txn = draft_transaction("internal", "internal")

      cmd = %PrepareTransaction{
        account_id: txn.account_id,
        staff_id: uuid4(),
        transaction_id: txn.id
      }

      expect(AccountServiceMock, :find, 2, fn(account_id) ->
        {:ok, %Account{id: account_id}}
      end)

      expect(StaffServiceMock, :find, 1, fn(account, staff_id) ->
        assert account.id == cmd.account_id
        assert staff_id == cmd.staff_id

        {:ok, %Worker{account_id: account.id, id: staff_id}}
      end)

      %{cmd: cmd, txn: txn}
    end

    test "source have zero stock", %{cmd: cmd, txn: txn} do
      serial_number = serial_number(cmd.account_id, %{remove_at: Timex.shift(Timex.now, days: -1)})
      add_entry(cmd.account_id, stock_id(:src, txn), [
        %EntryAdded{
          serial_number: serial_number,
          status: "committed",
          quantity: D.new(5)
        },
        %EntryAdded{
          status: "committed",
          quantity: D.new(7)
        },
        %EntryAdded{
          status: "planned",
          quantity: D.new(-7)
        }
      ])

      assert :ok = Router.dispatch(cmd)

      assert_event(TransactionPrepFailed, fn event ->
        event.transaction_id == cmd.transaction_id &&
        event.status == "zero_stock"
      end)
    end

    test "source have insufficient stock", %{cmd: cmd, txn: txn} do
      serial_number = serial_number(cmd.account_id, Timex.shift(Timex.now, days: 1))
      add_entry(cmd.account_id, stock_id(:src, txn), [
        %EntryAdded{
          serial_number: serial_number,
          status: "committed",
          quantity: D.new(2)
        },
        %EntryAdded{
          status: "committed",
          quantity: D.new(7)
        },
        %EntryAdded{
          status: "planned",
          quantity: D.new(-6)
        }
      ])

      assert :ok = Router.dispatch(cmd)

      assert_event(TransactionPrepared, fn event ->
        D.cmp(event.quantity, D.new(3)) == :eq &&
        event.status == "action_required"
      end)
    end

    test "source have enough stock from multiple batches combined", %{cmd: cmd, txn: txn} do
      serial_number = serial_number(cmd.account_id, Timex.shift(Timex.now, days: 1))
      add_entry(cmd.account_id, stock_id(:src, txn), [
        %EntryAdded{
          serial_number: serial_number,
          status: "committed",
          quantity: D.new(2)
        },
        %EntryAdded{
          status: "committed",
          quantity: D.new(7)
        },
        %EntryAdded{
          status: "planned",
          quantity: D.new(-4)
        }
      ])

      assert :ok = Router.dispatch(cmd)

      assert_event(TransactionPrepared, fn event ->
        D.cmp(event.quantity, D.new(5)) == :eq &&
        event.status == "ready"
      end)
    end
  end

  describe "dispatch command for transaction that decreased in quantity and" do
    setup do
      txn = draft_transaction("internal", "internal", events: [
        %TransactionPrepared{
          status: "ready",
          quantity: D.new(5)
        },
        %TransactionUpdated{
          effective_keys: [:quantity],
          quantity: D.new(1)
        }
      ])

      cmd = %PrepareTransaction{
        account_id: txn.account_id,
        staff_id: uuid4(),
        transaction_id: txn.id
      }

      expect(AccountServiceMock, :find, 2, fn(account_id) ->
        {:ok, %Account{id: account_id}}
      end)

      expect(StaffServiceMock, :find, 1, fn(account, staff_id) ->
        assert account.id == cmd.account_id
        assert staff_id == cmd.staff_id

        {:ok, %Worker{account_id: account.id, id: staff_id}}
      end)

      %{cmd: cmd, txn: txn}
    end

    test "multiple entries exist", %{cmd: cmd, txn: txn} do
      serial_number = serial_number(cmd.account_id, %{expires_at: Timex.shift(Timex.now, days: 1)})
      add_entry(cmd.account_id, stock_id(:src, txn), [
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
          transaction_id: cmd.transaction_id,
          serial_number: serial_number,
          entry_id: "E1",
          status: "planned",
          quantity: D.new(-2)
        },
        %EntryAdded{
          transaction_id: cmd.transaction_id,
          status: "planned",
          entry_id: "E2",
          quantity: D.new(-3)
        }
      ])

      add_entry(cmd.account_id, stock_id(:dst, txn), [
        %EntryAdded{
          transaction_id: cmd.transaction_id,
          serial_number: serial_number,
          entry_id: "E1",
          status: "planned",
          quantity: D.new(2)
        },
        %EntryAdded{
          transaction_id: cmd.transaction_id,
          status: "planned",
          entry_id: "E2",
          quantity: D.new(3)
        }
      ])

      assert :ok = Router.dispatch(cmd)

      assert_event(TransactionPrepRequested, fn event ->
        event.transaction_id == txn.id &&
        D.cmp(event.quantity, D.new(1)) &&
        D.cmp(event.quantity_prepared, D.new(5))
      end)

      assert_event(EntryDeleted, fn event ->
        event.entry_id == "E2" &&
        event.stock_id == stock_id(:src, txn)
      end)

      assert_event(EntryDeleted, fn event ->
        event.entry_id == "E2" &&
        event.stock_id == stock_id(:dst, txn)
      end)

      assert_event(EntryUpdated, fn event ->
        event.entry_id == "E1" &&
        event.stock_id == stock_id(:src, txn) &&
        D.cmp(event.quantity, D.new(-1))
      end)

      assert_event(EntryUpdated, fn event ->
        event.entry_id == "E1" &&
        event.stock_id == stock_id(:dst, txn) &&
        D.cmp(event.quantity, D.new(1))
      end)

      assert_event(TransactionPrepared, fn event ->
        D.cmp(event.quantity, D.new(-4)) == :eq &&
        event.status == "ready"
      end)
    end
  end

  describe "dispatch command where transaction increased in quantity and" do
    setup do
      txn = draft_transaction("internal", "internal", events: [
        %TransactionPrepared{
          status: "ready",
          quantity: D.new(5)
        },
        %TransactionUpdated{
          effective_keys: [:quantity],
          quantity: D.new(7)
        }
      ])

      cmd = %PrepareTransaction{
        account_id: txn.account_id,
        staff_id: uuid4(),
        transaction_id: txn.id
      }

      expect(AccountServiceMock, :find, 2, fn(account_id) ->
        {:ok, %Account{id: account_id}}
      end)

      expect(StaffServiceMock, :find, 1, fn(account, staff_id) ->
        assert account.id == cmd.account_id
        assert staff_id == cmd.staff_id

        {:ok, %Worker{account_id: account.id, id: staff_id}}
      end)

      %{cmd: cmd, txn: txn}
    end

    @tag :focus
    test "not enough stock exist", %{cmd: cmd, txn: txn} do
      serial_number = serial_number(cmd.account_id, Timex.shift(Timex.now, days: 1))
      add_entry(cmd.account_id, stock_id(:src, txn), [
        %EntryAdded{
          status: "committed",
          quantity: D.new(5)
        },
        %EntryAdded{
          serial_number: serial_number,
          status: "committed",
          quantity: D.new(5)
        },
        %EntryAdded{
          transaction_id: cmd.transaction_id,
          status: "planned",
          quantity: D.new(-5)
        },
        %EntryAdded{
          serial_number: serial_number,
          status: "planned",
          quantity: D.new(-4)
        }
      ])

      assert :ok = Router.dispatch(cmd)

      assert_event(TransactionPrepared, fn event ->
        D.cmp(event.quantity, D.new(1)) == :eq &&
        event.status == "action_required"
      end)
    end
  end
end
