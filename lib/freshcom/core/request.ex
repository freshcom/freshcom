defmodule Freshcom.Request do
  use TypedStruct

  typedstruct do
    field :requester_id, String.t()
    field :account_id, String.t()
    field :fields, map(), default: %{}
    field :identifiers, map(), default: %{}
    field :filter, list(), default: []
    field :search, String.t()
    field :pagination, map(), default: %{size: 25, number: 1}
    field :sort, list(), default: []
    field :include, [String.t()]
    field :locale, String.t()

    field :_requester_, map()
    field :_role_, String.t()
    field :_account_, map()
    field :_default_locale_, String.t()
    field :_include_filters_, map(), default: %{}
    field :_filterable_fields_, atom | list, default: :all
    field :_searchable_fields_, list, default: []
    field :_sortable_fields_, list, default: []
  end
end
