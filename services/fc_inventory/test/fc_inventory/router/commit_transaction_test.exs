defmodule FCInventory.Router.CommitTransactionTest do
  use FCBase.RouterCase

  import FCInventory.Fixture

  alias Decimal, as: D
  alias FCInventory.Router
  alias FCInventory.CommitTransaction
  alias FCInventory.{
    TransactionPrepared,
    EntryAdded,
    EntryCommitted,
    TransactionCommitRequested
  }

  setup do
    Application.ensure_all_started(:fc_inventory)
    :ok
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%CommitTransaction{})
    assert length(errors) > 0
  end

  describe "given valid command" do
    test "for a prepared transaction" do
      txn = draft_transaction("internal", "internal", events: [
        %TransactionPrepared{
          status: "ready",
          quantity: D.new(5)
        }
      ])

      cmd = %CommitTransaction{
        requester_role: "system",
        account_id: txn.account_id,
        transaction_id: txn.id
      }

      serial_number = serial_number(cmd.account_id)
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

      assert_event(TransactionCommitRequested, fn event ->
        event.transaction_id == cmd.transaction_id
      end)

      assert_event(EntryCommitted, fn event ->
        event.entry_id == "E1" &&
        event.stock_id == stock_id(:src, txn)
      end)

      assert_event(EntryCommitted, fn event ->
        event.entry_id == "E1" &&
        event.stock_id == stock_id(:dst, txn)
      end)

      assert_event(EntryCommitted, fn event ->
        event.entry_id == "E2" &&
        event.stock_id == stock_id(:src, txn)
      end)

      assert_event(EntryCommitted, fn event ->
        event.entry_id == "E2" &&
        event.stock_id == stock_id(:dst, txn)
      end)
    end
  end
end
