defmodule FCIdentity.DummyCommandWithEffectiveKeys do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :effective_keys, [atom], default: []

    field :a, String.t()
    field :b, String.t()
    field :c, String.t()

    validates :a, presence: true
    validates :b, presence: true
    validates :c, presence: true
  end
end