defmodule FCInventory.UpdateLineItem do
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

    field :effective_keys, [String.t()], default: []
    field :locale, String.t()

    field :movement_id, String.t()
    field :stockable_id, String.t()
    field :quantity, Decimal.t()

    field :name, String.t()
    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
  end

  validates :movement_id, presence: true, uuid: true
  validates :stockable_id, presence: true, uuid: true
  validates :quantity, presence: true
end
