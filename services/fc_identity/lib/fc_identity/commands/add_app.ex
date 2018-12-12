defmodule FCIdentity.AddApp do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :app_id, String.t()
    field :status, String.t(), default: "active"
    field :type, String.t(), default: "standard"
    field :name, String.t()
  end

  @valid_types ["system", "standard"]
  @valid_statuses ["active", "disabled"]

  validates :account_id, presence: [if: [type: "standard"]], uuid: [allow_blank: true, format: :default]
  validates :type, presence: true, inclusion: @valid_types
  validates :status, presence: true, inclusion: @valid_statuses
  validates :name, presence: true
end
