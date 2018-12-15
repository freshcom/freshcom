defmodule FCIdentity.UpdateApp do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()
    field :account_id, String.t()

    field :effective_keys, [String.t()], default: []

    field :app_id, String.t()
    field :name, String.t()

    validates :app_id, presence: true, uuid: true
    validates :name, presence: true
  end
end
