defmodule FCInventory.AddSerialNumber do
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

    field :serial_number, String.t()
    field :stockable_id, String.t()
    field :remove_at, DateTime.t()
    field :expires_at, DateTime.t()
  end
end
