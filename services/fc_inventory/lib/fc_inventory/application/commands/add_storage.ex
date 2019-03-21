defmodule FCInventory.AddStorage do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :request_id, String.t()
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()
    field :account_id, String.t()

    field :storage_id, String.t()

    field :status, String.t(), default: "active"
    field :type, String.t()
    field :number, String.t()

    field :name, String.t()
    field :short_name, String.t()
    field :label, String.t()

    field :address_line_one, String.t()
    field :address_line_two, String.t()
    field :address_city, String.t()
    field :address_region_code, String.t()
    field :address_country_code, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
  end

  @valid_statuses ["active", "disabled", "deleted"]

  validates :status, presence: true, inclusion: @valid_statuses
  validates :name, presence: true
end
