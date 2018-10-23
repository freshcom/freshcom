# defmodule MonkQL do
#   @moduledoc """

#   $eq, $gt, $gte, $in, $lt, $lte, $ne, $nin

#   $not, $and, $or

#   to_ecto_query(query, %{
#     "$or" => [
#       %{"label" => %{"$eq" => "test"}},
#       %{"quantity" => %{"$not" => %{"$gt" => 1.99}}}
#     ],
#     "type" => %{"$in" => ["standard", "custom"]}
#   })
#   """
#   def to_ecto_query(query, monkql_statements) do
#     to_ecto_query(query, "$and", monkql_statements)
#   end

#   defp to_ecto_query(query, "$and", statments) do
#     Enum.reduce(statments, query, fn({k, v}) ->
#       to_ecto_query(query, k, v)
#     end)
#   end

#   defp to_ecto_query(query, "$or", statments) do

#   end

#   defp to_ecto_query(query, "$not", statments) do

#   end

#   defp to_ecto_query(query, relationship <> "." <> field, statment) do

#   end
# end