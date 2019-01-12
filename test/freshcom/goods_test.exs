defmodule Freshcom.GoodsTest do
  use Freshcom.IntegrationCase
  import Freshcom.{Fixture, Shortcut}

  alias Freshcom.Goods

  describe "add_stockable/1" do
    # test "given invalid request" do
    #   assert {:error, %{errors: errors}} = Identity.add_app(%Request{})
    #   assert length(errors) > 0
    # end

    # test "given unauthorized requester" do
    #   req = %Request{
    #     account_id: uuid4(),
    #     data: %{
    #       "name" => "Test"
    #     }
    #   }

    #   assert {:error, :access_denied} = Identity.add_app(req)
    # end

    # test "given valid request by system" do
    #   req = %Request{
    #     _role_: "system",
    #     data: %{
    #       "type" => "system",
    #       "name" => "Test"
    #     }
    #   }

    #   assert {:ok, _} = Identity.add_app(req)
    # end

    @tag :focus
    test "given valid request by user" do
      requester = standard_user()
      client = system_app()

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        data: %{
          "status" => "active",
          "name" => "Test"
        }
      }

      assert {:ok, _} = Goods.add_stockable(req)
    end
  end
end