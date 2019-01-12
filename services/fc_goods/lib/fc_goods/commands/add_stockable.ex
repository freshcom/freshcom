defmodule FCGoods.AddStockable do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()
    field :account_id, String.t()

    field :name, String.t()
    field :status, String.t()
  end

  @valid_statuses ["draft", "active", "disabled", "deleted"]

  validates :status, presence: true, inclusion: @valid_statuses
  validates :name, presence: true
end
