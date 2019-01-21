defmodule Freshcom.GoodsTest do
  use Freshcom.IntegrationCase

  alias Freshcom.Goods

  describe "add_stockable/1" do
    test "given invalid request" do
      assert {:error, %{errors: errors}} = Goods.add_stockable(%Request{})
      assert length(errors) > 0
    end

    test "given unauthorized requester" do
      req = %Request{
        account_id: uuid4(),
        data: %{
          "name" => Faker.Commerce.product_name()
        }
      }

      assert {:error, :access_denied} = Goods.add_stockable(req)
    end

    test "given valid request by user" do
      requester = standard_user()
      client = system_app()

      req = %Request{
        requester_id: requester.id,
        client_id: client.id,
        account_id: requester.default_account_id,
        data: %{
          "avatar_id" => uuid4(),
          "status" => "active",
          "number" => "WD-12345",
          "barcode" => "94038503940912309",
          "name" => "Warp Drive",
          "label" => "gen3",
          "print_name" => "WARP DRV",
          "unit_of_measure" => "EA",
          "specification" => "Antimatter Engine x 1",
          "variable_weight" => false,
          "weight" => 200,
          "weight_unit" => "tons",
          "storage_type" => "frozen",
          "storage_description" => "keep at -150 C",
          "stackable" => false,
          "width" => 500,
          "length" => 500,
          "height" => 500,
          "dimension_unit" => "meters",
          "caption" => "A good core for your spaceship",
          "description" => "buy 1 get 1 free",
          "custom_data" => %{
            "fuel_type" => "antimatter"
          }
        }
      }

      assert {:ok, %{data: stockable}} = Goods.add_stockable(req)
      assert stockable.id
      assert stockable.status == req.data["status"]
      assert stockable.number == req.data["number"]
      assert stockable.barcode == req.data["barcode"]
      assert stockable.label == req.data["label"]
      assert stockable.print_name == req.data["print_name"]
      assert stockable.unit_of_measure == req.data["unit_of_measure"]
      assert stockable.specification == req.data["specification"]
      assert stockable.variable_weight == req.data["variable_weight"]
      assert stockable.weight == req.data["weight"]
      assert stockable.weight_unit == req.data["weight_unit"]
      assert stockable.storage_type == req.data["storage_type"]
      assert stockable.storage_size == req.data["storage_size"]
      assert stockable.storage_description == req.data["storage_description"]
      assert stockable.stackable == req.data["stackable"]
      assert stockable.width == req.data["width"]
      assert stockable.length == req.data["length"]
      assert stockable.height == req.data["height"]
      assert stockable.dimension_unit == req.data["dimension_unit"]
      assert stockable.caption == req.data["caption"]
      assert stockable.description == req.data["description"]
      assert stockable.custom_data == req.data["custom_data"]
    end
  end
end
