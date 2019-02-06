defmodule FCInventory.UpdateBatch do
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

    field :batch_id, String.t()

    field :status, String.t()
    field :number, String.t()
    field :name, String.t()
    field :label, String.t()
    field :quantity_on_hand, Decimal.t(), default: 0
    field :expires_at, DateTime.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
  end

  @valid_statuses ["active", "disabled", "deleted"]

  validates :batch_id, presence: true, uuid: true
  validates :status, presence: true, inclusion: @valid_statuses
end
