defmodule FCGoods.RouterTest do
  use FCBase.RouterCase, async: true

  alias FCGoods.Router
  alias FCGoods.{
    AddStockable,
    UpdateStockable
  }
  alias FCGoods.{
    StockableAdded,
    StockableUpdated
  }

  setup do
    Application.ensure_all_started(:fc_goods)

    :ok
  end

  describe "dispatch AddStockable" do
    setup do
      cmd = %AddStockable{
        name: Faker.String.base64(12)
      }

      %{cmd: cmd}
    end

    test "given invalid command" do
      assert {:error, {:validation_failed, errors}} = Router.dispatch(%AddStockable{})
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
      assert_receive_event(StockableAdded, fn(event) ->
        assert event.name == cmd.name
      end)
    end

    test "given valid command with system role", %{cmd: cmd} do
      assert :ok = Router.dispatch(%{cmd | requester_role: "system"})
      assert_receive_event(StockableAdded, fn(event) ->
        assert event.name == cmd.name
      end)
    end
  end

  describe "dispatch UpdateStockable" do
    setup do
      cmd = %UpdateStockable{
        name: Faker.Commerce.product_name()
      }

      %{cmd: cmd}
    end

    test "given invalid command" do
      assert {:error, {:validation_failed, errors}} = Router.dispatch(%UpdateStockable{})
      assert length(errors) > 0
    end

    test "given non existing stockable id", %{cmd: cmd} do
      assert {:error, {:not_found, :stockable}} = Router.dispatch(%{cmd | stockable_id: uuid4()})
    end

    test "given valid command with unauthorized role", %{cmd: cmd} do
      stockable_id = uuid4()
      to_streams("stockable", [
        %StockableAdded{
          client_id: uuid4(),
          account_id: uuid4(),
          requester_id: uuid4(),
          stockable_id: stockable_id,
          name: Faker.Commerce.product_name(),
          unit_of_measure: "EA"
        }
      ])

      assert {:error, :access_denied} = Router.dispatch(%{cmd | stockable_id: stockable_id})
    end

    test "given valid command with authorized role", %{cmd: cmd} do
      account_id = uuid4()
      client_id = app_id("standard", account_id)
      requester_id = user_id(account_id, "goods_specialist")
      stockable_id = uuid4()
      to_streams("stockable", [
        %StockableAdded{
          client_id: client_id,
          account_id: account_id,
          requester_id: requester_id,
          stockable_id: stockable_id,
          name: Faker.Commerce.product_name(),
          unit_of_measure: "EA"
        }
      ])

      cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id, stockable_id: stockable_id}

      assert :ok = Router.dispatch(cmd)
      assert_receive_event(StockableUpdated, fn(event) ->
        assert event.name == cmd.name
      end)
    end

    test "given valid command with system role", %{cmd: cmd} do
      stockable_id = uuid4()
      to_streams("stockable", [
        %StockableAdded{
          stockable_id: stockable_id,
          name: Faker.Commerce.product_name(),
          unit_of_measure: "EA"
        }
      ])

      cmd = %{cmd | requester_role: "system", stockable_id: stockable_id}

      assert :ok = Router.dispatch(cmd)
      assert_receive_event(StockableUpdated, fn(event) ->
        assert event.name == cmd.name
      end)
    end
  end
end