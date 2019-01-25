defmodule Freshcom.Filter do
  @moduledoc """
  ```
  [
    %{"$and" => [
      %{"$or" => [
        %{"role" => %{"$in" => ["supportSpecialist"]}},
        %{"role" => "supportSpecialist"}
      ]},
      %{"role" => "supportSpecialist"},
      %{"$or" => [
        %{"role" => %{"$eq" => "supportSpecialist"}},
        %{"role" => "supportSpecialist"}
      ]}
    ]}
  ]
  ```

  ## Operator Groups

  - Equality Operators: `"$eq"`, `"$in"`, `"$ne"`, `"$nin"`
  - Range Operators: `"$gt"`, `"$gte"`, `"$lt"`, `"$lte"`
  """

  import Ecto.Query
  import FCSupport.Normalization, only: [stringify_list: 1]

  alias Ecto.Queryable

  @spec attr_only(Ecto.Query.t(), [map], [String.t()]) :: Ecto.Query.t()
  def attr_only(query, [], _), do: query

  def attr_only(%Ecto.Query{} = query, statements, :all) do
    {_, queryable} = query.from
    permitted_fields = stringify_list(queryable.__schema__(:fields))

    dynamic = do_attr_only("$and", statements, permitted_fields)
    from(q in query, where: ^dynamic)
  end

  def attr_only(%Ecto.Query{} = query, statements, permitted_fields)
      when is_list(permitted_fields) do
    dynamic = do_attr_only("$and", statements, permitted_fields)
    from(q in query, where: ^dynamic)
  end

  defp do_attr_only(op, statements, permitted_fields) when op in ["$or", "$and"] do
    statements
    |> collect_dynamics(permitted_fields)
    |> combine_dynamics(op)
  end

  defp do_attr_only(attr, expression, permitted_fields) when is_binary(attr) do
    if is_field_permitted(attr, permitted_fields) do
      compare_attr(String.to_existing_atom(attr), expression)
    else
      nil
    end
  end

  defp collect_dynamics(statements, permitted_fields) do
    dynamics =
      Enum.reduce(statements, [], fn statement_or_expression, acc ->
        {operator_or_attr, statements_or_expression} = Enum.at(statement_or_expression, 0)
        acc ++ [do_attr_only(operator_or_attr, statements_or_expression, permitted_fields)]
      end)

    Enum.reject(dynamics, &is_nil/1)
  end

  defp combine_dynamics([d], _), do: d
  defp combine_dynamics([d1, d2], "$and"), do: dynamic([], ^d1 and ^d2)
  defp combine_dynamics([d1, d2], "$or"), do: dynamic([], ^d1 or ^d2)

  defp combine_dynamics([d1, d2 | rest], op) do
    acc = combine_dynamics([d1, d2], op)
    Enum.reduce(rest, acc, &combine_dynamics([&2, &1], op))
  end

  defp compare_attr(attr, nil) do
    dynamic([q], is_nil(field(q, ^attr)))
  end

  defp compare_attr(attr, %{"$eq" => nil}) do
    dynamic([q], is_nil(field(q, ^attr)))
  end

  defp compare_attr(attr, value) when not is_map(value) do
    dynamic([q], field(q, ^attr) == ^value)
  end

  defp compare_attr(attr, %{"$eq" => value}) do
    dynamic([q], field(q, ^attr) == ^value)
  end

  defp compare_attr(attr, %{"$gt" => value}) do
    dynamic([q], field(q, ^attr) > ^value)
  end

  defp compare_attr(attr, %{"$gte" => value}) do
    dynamic([q], field(q, ^attr) >= ^value)
  end

  defp compare_attr(attr, %{"$in" => value}) do
    dynamic([q], field(q, ^attr) in ^value)
  end

  defp compare_attr(attr, %{"$lt" => value}) do
    dynamic([q], field(q, ^attr) < ^value)
  end

  defp compare_attr(attr, %{"$lte" => value}) do
    dynamic([q], field(q, ^attr) <= ^value)
  end

  defp compare_attr(attr, %{"$ne" => nil}) do
    dynamic([q], not is_nil(field(q, ^attr)))
  end

  defp compare_attr(attr, %{"$ne" => value}) do
    dynamic([q], field(q, ^attr) != ^value)
  end

  defp compare_attr(attr, %{"$nin" => value}) do
    dynamic([q], not (field(q, ^attr) in ^value))
  end

  defp compare_attr(attr, %{"$btwn" => [s, e]}) do
    dynamic([q], field(q, ^attr) >= ^s and field(q, ^attr) <= ^e)
  end

  defp is_field_permitted(_, :all), do: true
  defp is_field_permitted(field, permitted_fields), do: field in permitted_fields

  @spec with_assoc(Ecto.Query.t(), [map], [String.t()], map) :: Ecto.Query.t()
  def with_assoc(query, expressions, permitted_fields, assoc_queries \\ %{}) do
    Enum.reduce(expressions, query, fn expression, acc_query ->
      {field, comparison} = Enum.at(expression, 0)

      if is_field_permitted(field, permitted_fields) do
        expression(acc_query, field, comparison, assoc_queries)
      else
        acc_query
      end
    end)
  end

  defp expression(query, field, comparison, assoc_queries) do
    if is_assoc(field) do
      {assoc, assoc_field} = assoc(field)
      assoc_assoc_queries = assoc_queries(assoc_queries, assoc)

      assoc_query =
        query
        |> assoc_query(assoc, assoc_queries)
        |> expression(assoc_field, comparison, assoc_assoc_queries)

      %{owner_key: owner_key, related_key: related_key} = reflection(query, assoc)

      from(q in query,
        join: aq in subquery(assoc_query),
        on: field(q, ^owner_key) == field(aq, ^related_key)
      )
    else
      dynamic = compare_attr(String.to_existing_atom(field), comparison)
      from(q in query, where: ^dynamic)
    end
  end

  @spec is_assoc(String.t()) :: boolean
  def is_assoc(field) do
    length(String.split(field, ".")) > 1
  end

  defp assoc(field) do
    splitted = String.split(field, ".")

    assoc = Enum.at(splitted, 0)
    assoc_field = Enum.join(Enum.slice(splitted, 1..-1), ".")

    {assoc, assoc_field}
  end

  defp assoc_queries(assoc_queries, target_assoc) do
    Enum.reduce(assoc_queries, %{}, fn {assoc, query}, acc ->
      if assoc != target_assoc && String.starts_with?(assoc, target_assoc) do
        {_, assoc_field} = assoc(assoc)
        Map.put(acc, assoc_field, query)
      else
        acc
      end
    end)
  end

  defp assoc_query(query, assoc, assoc_queries) do
    if assoc_queries[assoc] do
      assoc_queries[assoc]
    else
      reflection = reflection(query, assoc)
      Queryable.to_query(reflection.queryable)
    end
  end

  defp reflection(query, assoc) do
    {_, queryable} = query.from
    queryable.__schema__(:association, String.to_existing_atom(assoc))
  end

  @spec normalize(list, String.t(), function) :: list
  def normalize(filter, key, func) when is_list(filter) do
    Enum.map(filter, fn statement_or_expression ->
      {operator_or_attr, statements_or_expression} = Enum.at(statement_or_expression, 0)

      cond do
        String.starts_with?(operator_or_attr, "$") ->
          %{operator_or_attr => normalize(statements_or_expression, key, func)}

        operator_or_attr == key && is_map(statements_or_expression) ->
          {cmp, value} = Enum.at(statements_or_expression, 0)
          %{operator_or_attr => %{cmp => func.(value)}}

        operator_or_attr == key ->
          %{operator_or_attr => func.(statements_or_expression)}

        true ->
          statement_or_expression
      end
    end)
  end
end
