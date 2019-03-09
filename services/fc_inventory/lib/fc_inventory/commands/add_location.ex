defmodule FCInventory.AddLocation do
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

    field :location_id, String.t()
    field :parent_id, String.t()

    field :status, String.t(), default: "active"
    field :type, String.t(), default: "internal"
    field :number, String.t()

    field :name, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
  end

  @valid_statuses ["active", "disabled", "deleted"]

  validates :status, presence: true, inclusion: @valid_statuses
  validates :name, presence: true
end
