defmodule MonkQL do
  @moduledoc """

  $eq, $gt, $gte, $in, $lt, $lte, $ne, $nin

  $not, $and, $or

  to_ecto_query(query, %{
    "$or" => [
      %{"label" => %{"$eq" => "test"}},
      %{"quantity" => %{"$not" => %{"$gt" => 1.99}}}
    ],
    "type" => %{"$in" => ["standard", "custom"]}
  })
  """

  import Ecto.Query
  alias Ecto.Queryable

  def to_ecto_query(query, statments, permitted_fields, assoc_queries) do
    statments(query, "$and", statments, permitted_fields, assoc_queries)
  end

  def statments(query, "$and", statments, permitted_fields, assoc_queries) do
    Enum.reduce(statments, query, fn({operator_or_field, statments_or_comparison}, acc_query) ->
      statments(acc_query, operator_or_field, statments_or_comparison, permitted_fields, assoc_queries)
    end)
  end

  def statments(query, "$or", statments, permitted_fields, assoc_queries) do

  end

  def statments(query, "$not", statments, permitted_fields, assoc_queries) do

  end

  def statments(_, "$"<>_ = lop, _, _, _), do: {:error, {:invalid_operator, lop}}

  def statments(query, field, comparison, permitted_fields, assoc_queries) do
    if field in permitted_fields do
      compare_field(query, field, comparison, assoc_queries)
    else
      {:error, {:invalid_field, field}}
    end
  end

  def compare_field(query, field, comparison, assoc_queries) do
    splitted = String.split(field, ".")

    if length(splitted) > 1 do
      {assoc, assoc_field} = assoc(field)
      assoc_query = assoc_query(query, assoc, assoc_queries)
      assoc_assoc_queries = assoc_queries(assoc_queries, assoc)
      compared_assoc_query = comparison(assoc_query, assoc_field, comparison, assoc_assoc_queries)

      %{owner_key: owner_key, related_key: related_key} = reflection(query, assoc)
      from(q in query,
        join: caq in subquery(compared_assoc_query),
        on: field(q, ^owner_key) == field(caq, ^related_key),
        select: q
      )
    else
      compare_attr(query, String.to_existing_atom(field), comparison)
    end
  end

  @spec compare_attr(Ecto.Query.t(), atom, map) :: Ecto.Query.t()
  def compare_attr(query, attr, %{"$eq" => nil}) do
    from(q in query, where: is_nil(field(q, ^attr)))
  end

  def compare_attr(query, attr, %{"$eq" => value}) do
    from(q in query, where: field(q, ^attr) == ^value)
  end

  def compare_attr(query, attr, %{"$gt" => value}) do
    from(q in query, where: field(q, ^attr) > ^value)
  end

  def compare_attr(query, attr, %{"$gte" => value}) do
    from(q in query, where: field(q, ^attr) >= ^value)
  end

  def compare_attr(query, attr, %{"$in" => value}) do
    from(q in query, where: field(q, ^attr) in ^value)
  end

  def compare_attr(query, attr, %{"$le" => value}) do
    from(q in query, where: field(q, ^attr) < ^value)
  end

  def compare_attr(query, attr, %{"$lte" => value}) do
    from(q in query, where: field(q, ^attr) <= ^value)
  end

  def compare_attr(query, attr, %{"$ne" => nil}) do
    from(q in query, where: not(is_nil(field(q, ^attr))))
  end

  def compare_attr(query, attr, %{"$ne" => value}) do
    from(q in query, where: field(q, ^attr) != ^value)
  end

  def compare_attr(query, attr, %{"$nin" => value}) do
    from(q in query, where: not(field(q, ^attr) in ^value))
  end

  def compare_attr(query, attr, value) when not is_map(value) do
    compare_attr(query, attr, %{"$eq" => value})
  end

  def assoc(field) do
    splitted = String.split(field, ".")

    assoc = Enum.at(splitted, 0)
    assoc_field = Enum.join(Enum.slice(splitted, 1..-1), ".")

    {assoc, assoc_field}
  end

  def assoc_queries(assoc_queries, target_assoc) do
    Enum.reduce(assoc_queries, %{}, fn({assoc, query}, acc) ->
      if assoc != target_assoc && String.starts_with?(assoc, target_assoc) do
        {_, assoc_field} = assoc(assoc)
        Map.put(acc, assoc_field, query)
      else
        acc
      end
    end)
  end

  @doc """
  Returns the association query.

  If a corresponding query exist in `assoc_queries` then it will be returned otherwise
  this function will attempt to build a default query.
  """
  def assoc_query(query, assoc, assoc_queries) do
    if assoc_queries[assoc] do
      assoc_queries[assoc]
    else
      reflection = reflection(query, assoc)
      default_query = Queryable.to_query(reflection.queryable)
    end
  end

  def reflection(query, assoc) do
    {_, queryable} = query.from
    queryable.__schema__(:association, String.to_existing_atom(assoc))
  end
end