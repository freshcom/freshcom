defmodule Freshcom.Request do
  use TypedStruct

  typedstruct do
    field :requester, map(), default: %{id: nil, account_id: nil}
    field :fields, map(), default: %{}
    field :identifiers, map(), default: %{}
    field :filter, map(), default: %{}
    field :search, String.t()
    field :pagination, map(), default: %{size: 25, number: 1}
    field :sort, list(), default: []
    field :include, [String.t()]
    field :locale, String.t()

    field :_include_filters_, map(), default: %{}
    field :_filterable_fields_, atom | list, default: :all
    field :_searchable_fields_, list, default: []
  end
end
