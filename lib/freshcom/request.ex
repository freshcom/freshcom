defmodule Freshcom.Request do
  use TypedStruct

  typedstruct do
    field :requester, map()
    field :fields, map()
    field :identifiers, map()
  end
end