defmodule FCInventory.Router.UpdateTransactionTest do
  use FCBase.RouterCase

  alias Decimal, as: D
  alias FCInventory.{AccountServiceMock, StaffServiceMock}
  alias FCInventory.{Account, Worker}
  alias FCInventory.Router
  alias FCInventory.UpdateTransaction
  alias FCInventory.{
    TransactionDrafted, TransactionUpdated
  }

  setup do
    account_id = uuid4()
    txn_id = uuid4()

    to_streams(:transaction_id, "inventory-transaction-", [
      %TransactionDrafted{
        account_id: account_id,
        transaction_id: txn_id,
        source_id: uuid4(),
        destination_id: uuid4(),
        sku_id: uuid4(),
        quantity: Decimal.new(7)
      }
    ])

    cmd = %UpdateTransaction{
      account_id: account_id,
      staff_id: uuid4(),
      transaction_id: txn_id,
      effective_keys: [:summary, :quantity],
      summary: "Annual Check 123",
      quantity: D.new(5)
    }

    %{cmd: cmd}
  end

  test "dispatch invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%UpdateTransaction{})
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

      assert_receive_event(TransactionUpdated, fn event ->
        assert event.summary == cmd.summary
        assert event.quantity == cmd.quantity
        assert D.cmp(event.original_fields.quantity, D.new(7)) == :eq
      end)
    end
  end
end
