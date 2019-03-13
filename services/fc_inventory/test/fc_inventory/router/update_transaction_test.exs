defmodule FCInventory.Router.UpdateTransactionTest do
  use FCBase.RouterCase

  alias Decimal, as: D
  alias Faker.Company
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
        stockable_id: uuid4(),
        quantity: Decimal.new(7)
      }
    ])

    cmd = %UpdateTransaction{
      account_id: account_id,
      transaction_id: txn_id,
      effective_keys: [:name, :quantity],
      name: "Annual Check 123",
      quantity: D.new(5)
    }

    %{cmd: cmd}
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%UpdateTransaction{})
    assert length(errors) > 0
  end

  describe "given valid command with" do
    test "authorized role", %{cmd: cmd} do
      client_id = app_id("standard", cmd.account_id)
      requester_id = user_id(cmd.account_id, "goods_specialist")

      cmd = %{cmd | client_id: client_id, requester_id: requester_id}

      assert :ok = Router.dispatch(cmd)

      assert_receive_event(TransactionUpdated, fn event ->
        assert event.name == cmd.name
      end)
    end

    test "system role", %{cmd: cmd} do
      assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

      assert_receive_event(TransactionUpdated, fn event ->
        assert event.name == cmd.name
      end)
    end
  end

  # test "given valid command with authorized role", %{cmd: cmd} do
  #   account_id = uuid4()
  #   client_id = app_id("standard", account_id)
  #   requester_id = user_id(account_id, "goods_specialist")

  #   to_streams(:storage_id, "stock-storage-", [
  #     %TransactionAdded{
  #       storage_id: cmd.storage_id,
  #       name: Company.name()
  #     }
  #   ])

  #   cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

  #   assert :ok = Router.dispatch(cmd)

  #   assert_receive_event(TransactionUpdated, fn event ->
  #     assert event.name == cmd.name
  #   end)
  # end

  # test "given valid command with system role", %{cmd: cmd} do
  #   to_streams(:storage_id, "stock-storage-", [
  #     %TransactionAdded{
  #       storage_id: cmd.storage_id,
  #       name: Company.name()
  #     }
  #   ])

  #   cmd = %{cmd | requester_role: "system"}

  #   assert :ok = Router.dispatch(cmd)

  #   assert_receive_event(TransactionUpdated, fn event ->
  #     assert event.name == cmd.name
  #   end)
  # end
end
