defmodule FCGoods.UpdateStockable do
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

    field :stockable_id, String.t()
    field :avatar_id, String.t()

    field :status, String.t()
    field :number, String.t()
    field :barcode, String.t()

    field :name, String.t()
    field :label, String.t()
    field :print_name, String.t()
    field :unit_of_measure, String.t()
    field :specification, String.t()

    field :variable_weight, boolean()
    field :weight, Decimal.t()
    field :weight_unit, String.t()

    field :storage_type, String.t()
    field :storage_size, integer()
    field :storage_description, String.t()
    field :stackable, boolean()

    field :width, Decimal.t()
    field :length, Decimal.t()
    field :height, Decimal.t()
    field :dimension_unit, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
  end

  @valid_statuses ["draft", "active", "disabled", "deleted"]

  validates :stockable_id, presence: true

  validates :status, presence: true, inclusion: @valid_statuses
  validates :name, presence: true
  validates :unit_of_measure, presence: true
end
