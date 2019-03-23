defmodule FCInventory.Account do
  use TypedStruct

  typedstruct do
    field :id, String.t(), enforce: true
  end
end