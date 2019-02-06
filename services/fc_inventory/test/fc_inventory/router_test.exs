defmodule FCInventory.RouterTest do
  use FCBase.RouterCase, async: true

  alias FCInventory.Router
  alias Faker.{Company, Lorem}

  alias FCInventory.{
    AddStorage,
    UpdateStorage,
    DeleteStorage,
    AddBatch,
    UpdateBatch
  }

  alias FCInventory.{
    StorageAdded,
    StorageUpdated,
    StorageDeleted,
    BatchAdded,
    BatchUpdated
  }

  setup do
    Application.ensure_all_started(:fc_inventory)

    :ok
  end

  describe "dispatch AddStorage" do
    setup do
      cmd = %AddStorage{
        name: Faker.String.base64(12)
      }

      %{cmd: cmd}
    end

    test "given invalid command" do
      assert {:error, {:validation_failed, errors}} = Router.dispatch(%AddStorage{})
      assert length(errors) > 0
    end

    test "given valid command with unauthorized role", %{cmd: cmd} do
      assert {:error, :access_denied} = Router.dispatch(cmd)
    end

    test "given valid command with authorized role", %{cmd: cmd} do
      account_id = uuid4()
      requester_id = user_id(account_id, "goods_specialist")
      client_id = app_id("standard", account_id)

      cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

      assert :ok = Router.dispatch(cmd)

      assert_receive_event(StorageAdded, fn event ->
        assert event.name == cmd.name
      end)
    end

    test "given valid command with system role", %{cmd: cmd} do
      assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

      assert_receive_event(StorageAdded, fn event ->
        assert event.name == cmd.name
      end)
    end
  end

  describe "dispatch UpdateStorage" do
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

    test "given non existing storage id", %{cmd: cmd} do
      assert {:error, {:not_found, :storage}} = Router.dispatch(cmd)
    end

    test "given valid command with unauthorized role", %{cmd: cmd} do
      to_streams("storage", [
        %StorageAdded{
          client_id: uuid4(),
          account_id: uuid4(),
          requester_id: uuid4(),
          storage_id: cmd.storage_id,
          name: Company.name()
        }
      ])

      assert {:error, :access_denied} = Router.dispatch(cmd)
    end

    test "given valid command with authorized role", %{cmd: cmd} do
      account_id = uuid4()
      client_id = app_id("standard", account_id)
      requester_id = user_id(account_id, "goods_specialist")

      to_streams("storage", [
        %StorageAdded{
          client_id: client_id,
          account_id: account_id,
          requester_id: requester_id,
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
      to_streams("storage", [
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

  describe "dispatch DeleteStorage" do
    setup do
      cmd = %DeleteStorage{
        storage_id: uuid4()
      }

      %{cmd: cmd}
    end

    test "given invalid command" do
      assert {:error, {:validation_failed, errors}} = Router.dispatch(%DeleteStorage{})
      assert length(errors) > 0
    end

    test "given non existing storage id", %{cmd: cmd} do
      assert {:error, {:not_found, :storage}} = Router.dispatch(cmd)
    end

    test "given valid command with unauthorized role", %{cmd: cmd} do
      to_streams("storage", [
        %StorageAdded{
          client_id: uuid4(),
          account_id: uuid4(),
          requester_id: uuid4(),
          storage_id: cmd.storage_id,
          name: Company.name()
        }
      ])

      assert {:error, :access_denied} = Router.dispatch(cmd)
    end

    test "given valid command with authorized role", %{cmd: cmd} do
      account_id = uuid4()
      client_id = app_id("standard", account_id)
      requester_id = user_id(account_id, "goods_specialist")

      to_streams("storage", [
        %StorageAdded{
          client_id: client_id,
          account_id: account_id,
          requester_id: requester_id,
          storage_id: cmd.storage_id,
          name: Company.name()
        }
      ])

      cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

      assert :ok = Router.dispatch(cmd)

      assert_receive_event(StorageDeleted, fn event ->
        assert event.storage_id == cmd.storage_id
      end)
    end

    test "given valid command with system role", %{cmd: cmd} do
      to_streams("storage", [
        %StorageAdded{
          storage_id: cmd.storage_id,
          name: Company.name()
        }
      ])

      cmd = %{cmd | requester_role: "system"}

      assert :ok = Router.dispatch(cmd)

      assert_receive_event(StorageDeleted, fn event ->
        assert event.storage_id == cmd.storage_id
      end)
    end
  end

  describe "dispatch AddBatch" do
    setup do
      cmd = %AddBatch{
        stockable_id: uuid4(),
        storage_id: uuid4(),
        number: Lorem.characters(12)
      }

      %{cmd: cmd}
    end

    test "given invalid command" do
      assert {:error, {:validation_failed, errors}} = Router.dispatch(%AddBatch{})
      assert length(errors) > 0
    end

    test "given valid command with unauthorized role", %{cmd: cmd} do
      assert {:error, :access_denied} = Router.dispatch(cmd)
    end

    test "given valid command with authorized role", %{cmd: cmd} do
      account_id = uuid4()
      requester_id = user_id(account_id, "goods_specialist")
      client_id = app_id("standard", account_id)

      cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

      assert :ok = Router.dispatch(cmd)

      assert_receive_event(BatchAdded, fn event ->
        assert event.number == cmd.number
      end)
    end

    test "given valid command with system role", %{cmd: cmd} do
      assert :ok = Router.dispatch(%{cmd | requester_role: "system"})

      assert_receive_event(BatchAdded, fn event ->
        assert event.number == cmd.number
      end)
    end
  end

  describe "dispatch UpdateBatch" do
    setup do
      cmd = %UpdateBatch{
        batch_id: uuid4(),
        number: Lorem.characters(12)
      }

      %{cmd: cmd}
    end

    test "given invalid command" do
      assert {:error, {:validation_failed, errors}} = Router.dispatch(%UpdateBatch{})
      assert length(errors) > 0
    end

    test "given non existing batch id", %{cmd: cmd} do
      assert {:error, {:not_found, :batch}} = Router.dispatch(cmd)
    end

    test "given valid command with unauthorized role", %{cmd: cmd} do
      to_streams("batch", [
        %BatchAdded{
          client_id: uuid4(),
          account_id: uuid4(),
          requester_id: uuid4(),
          batch_id: cmd.batch_id
        }
      ])

      assert {:error, :access_denied} = Router.dispatch(cmd)
    end

    test "given valid command with authorized role", %{cmd: cmd} do
      account_id = uuid4()
      client_id = app_id("standard", account_id)
      requester_id = user_id(account_id, "goods_specialist")

      to_streams("batch", [
        %BatchAdded{
          client_id: client_id,
          account_id: account_id,
          requester_id: requester_id,
          batch_id: cmd.batch_id
        }
      ])

      cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

      assert :ok = Router.dispatch(cmd)

      assert_receive_event(BatchUpdated, fn event ->
        assert event.number == cmd.number
      end)
    end

    test "given valid command with system role", %{cmd: cmd} do
      to_streams("batch", [
        %BatchAdded{
          batch_id: cmd.batch_id
        }
      ])

      cmd = %{cmd | requester_role: "system"}

      assert :ok = Router.dispatch(cmd)

      assert_receive_event(BatchUpdated, fn event ->
        assert event.number == cmd.number
      end)
    end
  end
end
