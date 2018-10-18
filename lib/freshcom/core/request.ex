defmodule Freshcom.Request do
  use TypedStruct

  typedstruct do
    field :requester, map(), default: %{requester_id: nil, account_id: nil}
    field :fields, map(), default: %{}
    field :identifiers, map(), default: %{}
    field :locale, String.t()
  end
end