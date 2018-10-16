defmodule Freshcom.Response do
  use TypedStruct

  typedstruct do
    field :meta, map(), default: %{}
    field :data, map()
    field :errors, map(), default: []
  end

  def put_meta(response, key, value) do
    new_meta = Map.put(response.meta, key, value)
    Map.put(response, :meta, new_meta)
  end
end