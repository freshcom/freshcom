defmodule FCGoods.RouterTest do
  use FCBase.RouterCase, async: true

  alias FCGoods.Router
  alias FCGoods.{
    AddStockable
  }
  alias FCGoods.{
    StockableAdded
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
      {:error, {:validation_failed, errors}} = Router.dispatch(%AddStockable{})
      assert length(errors) > 0
    end

    test "given valid command with unauthorized role", %{cmd: cmd} do
      {:error, :access_denied} = Router.dispatch(cmd)
    end

    test "given valid command with authorized role", %{cmd: cmd} do
      account_id = uuid4()
      requester_id = user_id(account_id, "goods_specialist")
      client_id = app_id("standard", account_id)

      cmd = %{cmd | client_id: client_id, account_id: account_id, requester_id: requester_id}
      :ok = Router.dispatch(cmd)

      assert_receive_event(StockableAdded, fn(event) ->
        assert event.name == cmd.name
      end)
    end

    test "given valid command with system role", %{cmd: cmd} do
      :ok = Router.dispatch(%{cmd | requester_role: "system"})

      assert_receive_event(StockableAdded, fn(event) ->
        assert event.name == cmd.name
      end)
    end
  end
end