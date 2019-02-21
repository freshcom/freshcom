defmodule FCInventory.Router.UpdateStorageTest do
  use FCBase.RouterCase

  alias Faker.Company
  alias FCInventory.Router
  alias FCInventory.UpdateStorage
  alias FCInventory.{StorageAdded, StorageUpdated}

  setup do
    cmd = %UpdateStorage{
      storage_id: uuid4(),
      name: Company.name()
    }

    %{cmd: cmd}
  end

  test "given invalid command" do
    assert {:error, {:validation_failed, errors}} = Router.dispatch(%UpdateStorage{})
    assert length(errors) > 0
  end

  test "given valid command with authorized role", %{cmd: cmd} do
    account_id = uuid4()
    client_id = app_id("standard", account_id)
    requester_id = user_id(account_id, "goods_specialist")

    to_streams(:storage_id, "stock-storage-", [
      %StorageAdded{
        storage_id: cmd.storage_id,
        name: Company.name()
      }
    ])

    cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

    assert :ok = Router.dispatch(cmd)

    assert_receive_event(StorageUpdated, fn event ->
      assert event.name == cmd.name
    end)
  end

  test "given valid command with system role", %{cmd: cmd} do
    to_streams(:storage_id, "stock-storage-", [
      %StorageAdded{
        storage_id: cmd.storage_id,
        name: Company.name()
      }
    ])

    cmd = %{cmd | requester_role: "system"}

    assert :ok = Router.dispatch(cmd)

    assert_receive_event(StorageUpdated, fn event ->
      assert event.name == cmd.name
    end)
  end
end
