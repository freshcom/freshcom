defmodule Freshcom.Fixture.Goods do
  alias Faker.Commerce
  alias Freshcom.{Request, Goods}

  def stockable(account_id, opts \\ []) do
    req = %Request{
      account_id: account_id,
      data: %{
        name: Commerce.product_name()
      },
      include: opts[:include],
      _role_: "system"
    }

    {:ok, %{data: stockable}} = Goods.add_stockable(req)

    stockable
  end
end
