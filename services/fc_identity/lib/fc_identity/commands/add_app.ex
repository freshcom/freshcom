defmodule FCIdentity.AddApp do
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

    field :app_id, String.t()
    field :type, String.t(), default: "standard"
    field :name, String.t()
  end

  @valid_types ["system", "standard"]

  validates :account_id, presence: [if: [type: "standard"]], uuid: [allow_blank: true, format: :default]
  validates :type, presence: true, inclusion: @valid_types
  validates :name, presence: true
end
