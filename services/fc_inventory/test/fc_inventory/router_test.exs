defmodule FCInventory.RouterTest do
  use FCBase.RouterCase, async: true

  alias FCInventory.Router
  alias Faker.Company

  alias FCInventory.{
    AddStorage,
    UpdateStorage
  }

  alias FCInventory.{
    StorageAdded,
    StorageUpdated
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

  # describe "dispatch DeleteStockable" do
  #   setup do
  #     cmd = %DeleteStockable{
  #       stockable_id: uuid4()
  #     }

  #     %{cmd: cmd}
  #   end

  #   test "given invalid command" do
  #     assert {:error, {:validation_failed, errors}} = Router.dispatch(%DeleteStockable{})
  #     assert length(errors) > 0
  #   end

  #   test "given non existing stockable id", %{cmd: cmd} do
  #     assert {:error, {:not_found, :stockable}} = Router.dispatch(cmd)
  #   end

  #   test "given valid command with unauthorized role", %{cmd: cmd} do
  #     to_streams("stockable", [
  #       %StockableAdded{
  #         client_id: uuid4(),
  #         account_id: uuid4(),
  #         requester_id: uuid4(),
  #         stockable_id: cmd.stockable_id,
  #         name: Faker.Commerce.product_name(),
  #         unit_of_measure: "EA"
  #       }
  #     ])

  #     assert {:error, :access_denied} = Router.dispatch(cmd)
  #   end

  #   test "given valid command with authorized role", %{cmd: cmd} do
  #     account_id = uuid4()
  #     client_id = app_id("standard", account_id)
  #     requester_id = user_id(account_id, "goods_specialist")

  #     to_streams("stockable", [
  #       %StockableAdded{
  #         client_id: client_id,
  #         account_id: account_id,
  #         requester_id: requester_id,
  #         stockable_id: cmd.stockable_id,
  #         name: Faker.Commerce.product_name(),
  #         unit_of_measure: "EA"
  #       }
  #     ])

  #     cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}

  #     assert :ok = Router.dispatch(cmd)

  #     assert_receive_event(StockableDeleted, fn event ->
  #       assert event.stockable_id == cmd.stockable_id
  #     end)
  #   end

  #   test "given valid command with system role", %{cmd: cmd} do
  #     to_streams("stockable", [
  #       %StockableAdded{
  #         stockable_id: cmd.stockable_id,
  #         name: Faker.Commerce.product_name(),
  #         unit_of_measure: "EA"
  #       }
  #     ])

  #     cmd = %{cmd | requester_role: "system"}

  #     assert :ok = Router.dispatch(cmd)

  #     assert_receive_event(StockableDeleted, fn event ->
  #       assert event.stockable_id == cmd.stockable_id
  #     end)
  #   end
  # end
end
