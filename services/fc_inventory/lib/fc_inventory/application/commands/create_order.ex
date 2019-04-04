defmodule FCInventory.CreateOrder do
  use TypedStruct
  use Vex.Struct

  alias FCInventory.LineItem
  alias FCInventory.{Account, Staff}

  typedstruct do
    field :request_id, String.t()
    field :account_id, String.t()
    field :staff_id, String.t()

    field :order_id, String.t()
    field :location_id, String.t()
    field :status, String.t(), default: "draft"
    field :line_items, [LineItem.t()], default: []

    field :name, String.t()
    field :email, String.t()
    field :phone_number, String.t()

    field :shipping_address_line_one, String.t()
    field :shipping_address_line_two, String.t()
    field :shipping_address_city, String.t()
    field :shipping_address_province, String.t()
    field :shipping_address_country_code, String.t()
    field :shipping_address_postal_code, String.t()

    field :_account_, Account.t()
    field :_staff_, Staff.t()
  end

  validates :account_id, presence: true, uuid: true
  validates :staff_id, presence: true
  validates :location_id, presence: true, uuid: true
  validates :status, presence: true, inclusion: ["draft", "pending", "hold"]
end
