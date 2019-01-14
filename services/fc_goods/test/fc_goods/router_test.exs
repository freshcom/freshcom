defmodule FCGoods.RouterTest do
  use FCGoods.RouterCase, async: true

  alias FCGoods.Router
  alias FCGoods.{
    AddStockable
  }
  alias FCGoods.{
    StockableAdded
  }

  describe "dispatch AddStockable" do
    test "given valid command with system role" do
      cmd = %AddStockable{
        requester_role: "system",
        name: Faker.String.base64(12)
      }
      :ok = Router.dispatch(cmd)

      assert_receive_event(StockableAdded, fn(event) ->
        assert event.name == cmd.name
      end)
    end
  end
end