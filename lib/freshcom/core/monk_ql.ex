defmodule MonkQL do
  @moduledoc """

  $eq, $gt, $gte, $in, $lt, $lte, $ne, $nin

  $not, $and, $or

  to_ecto_query(query, %{
    "$or" => [
      %{"label" => %{"$eq" => "test"}},
      %{"quantity" => %{"$not" => %{"$not" => %{"$gt" => 1.99}}}}
    ],
    "type" => %{"$in" => ["standard", "custom"]}
  })

  to_ecto_query(query, %{
    "$or" => [
      %{"$and" => [
        %{"test1" => "lol"},
        %{"test2" => "woot"}
      ]},
      %{"quantity" => %{"$not" => %{"$not" => %{"$gt" => 1.99}}}},
      %{"$and" => [
        %{"test1" => "lol"},
        %{"test2" => "woot"}
      ]}
    ],
    "type" => %{"$in" => ["standard", "custom"]}
  })
  """

  # (test1 = 'lol' AND test2 = 'woot')

  import Ecto.Query
  alias Ecto.Queryable

  def to_ecto_query(query, statements, permitted_fields, assoc_queries) do
    statements(query, statements, permitted_fields, assoc_queries)
  end

  def statements(query, %{"$and" => statements}, permitted_fields, assoc_queries) do
    Enum.reduce(statements, query, fn(statement, acc_query) ->
      statements(acc_query, statement, permitted_fields, assoc_queries)
    end)
  end

  def statements(query, %{"$or" => statements}, permitted_fields, assoc_queries) do
    Enum.reduce(statements, query, fn(statement, acc_query) ->
      statements(acc_query, statement, permitted_fields, assoc_queries)
    end)
  end

  def statements(_, "$"<>_ = lop, _, _, _), do: {:error, {:invalid_operator, lop}}

  def statements(query, comparison, permitted_fields, assoc_queries) when map_size(comparison) == 1 do
    {field, expression} = Enum.at(comparison, 0)

    if permitted_fields == :all || field in permitted_fields do
      compare_field(query, field, expression, assoc_queries)
    else
      {:error, {:invalid_field, field}}
    end
  end

  def statements(_, comparison, _, _), do: {:error, {:invalid_comparison, comparison}}

  def compare_field(query, field, expression, assoc_queries) do
    splitted = String.split(field, ".")

    if length(splitted) > 1 do
      {assoc, assoc_field} = assoc(field)
      assoc_query = assoc_query(query, assoc, assoc_queries)
      assoc_assoc_queries = assoc_queries(assoc_queries, assoc)
      compared_assoc_query = compare_field(assoc_query, assoc_field, expression, assoc_assoc_queries)

      %{owner_key: owner_key, related_key: related_key} = reflection(query, assoc)
      from(q in query,
        join: caq in subquery(compared_assoc_query),
        on: field(q, ^owner_key) == field(caq, ^related_key),
        select: q
      )
    else
      compare_attr(query, String.to_existing_atom(field), expression)
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