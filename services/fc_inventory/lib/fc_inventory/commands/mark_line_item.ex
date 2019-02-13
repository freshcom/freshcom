defmodule FCInventory.MarkLineItem do
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

    field :line_item_id, String.t()
    field :status, String.t()
  end

  @valid_statuses ["drafted"]

  validates :line_item_id, presence: true, uuid: true
  validates :status, presence: true, inclusion: @valid_statuses
end
