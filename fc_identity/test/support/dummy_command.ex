defmodule FCIdentity.DummyCommand do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :a, String.t()
    field :b, String.t()
    field :c, String.t()

    validates :a, presence: true
    validates :b, presence: true
    validates :c, presence: true
  end
end