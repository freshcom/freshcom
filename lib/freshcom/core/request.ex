defmodule Freshcom.Request do
  @moduledoc """
  Use this module to wrap and modify request data to pass in to API functions.

  ## Fields

  - `requester_id` - The user's ID that is making this request.
  - `client_id` - The app's ID that is making the request on behalf of the user.
  - `account_id` - The target account's ID.
  - `filter` - A filter to apply if you are calling an API function that list some resources. Please see `Freshcom.Filter` for the format of the filter to provide.

  All other fields are self explanatory. Not all fields are used for all API functions,
  for example if you provide a pagination for a function that create a single resource
  it will have no effect.

  Fields in the form of `_****_` are not meant to be directly used, you should never
  set them to any user provided data. These fields are used by the internal system.
  """

  use TypedStruct

  typedstruct do
    field :requester_id, String.t()
    field :client_id, String.t()
    field :account_id, String.t()
    field :data, map(), default: %{}
    field :identifier, map(), default: %{}
    field :filter, list(), default: []
    field :search, String.t()
    field :pagination, map() | nil, default: %{size: 25, number: 1}
    field :sort, list(), default: []
    field :include, [String.t()]
    field :locale, String.t()

    field :_requester_, map()
    field :_client_, map()
    field :_role_, String.t()
    field :_account_, map()
    field :_default_locale_, String.t()
    field :_identifiable_fields_, atom | [String.t()], default: :all
    field :_include_filters_, map(), default: %{}
    field :_filterable_fields_, atom | [String.t()], default: :all
    field :_searchable_fields_, [String.t()], default: []
    field :_sortable_fields_, [String.t()], default: []
  end

  def put(req, root_key, key, value) do
    root_value =
      req
      |> Map.get(root_key)
      |> Map.put(key, value)

    Map.put(req, root_key, root_value)
  end

  def put(req, key, value), do: Map.put(req, key, value)
end
