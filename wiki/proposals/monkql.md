# MonkQL

MonkQL is a lightweight MongoDB style query language where the entire query can be constructed using JSON, URL query string or Elixir map. The goals are as follows:

1. Provide a unified way that allow client to query for resources on the server.
2. Provide a implementation that can easily and safely convert MonkQL to ecto queries.

Since JSON or URL query string can be easily converted into Elixir map and this is going to be implemented using Elixir all example in this document will use Elixir map as the actual query.

## Operators

MonkQL will implement a subset of MongoDB operators.

**Comparison Operators**

| Operator | Description                                                         |
|----------|---------------------------------------------------------------------|
| $eq      | Matches values that are equal to a specified value.                 |
| $gt      | Matches values that are greater than a specified value.             |
| $gte     | Matches values that are greater than or equal to a specified value. |
| $in      | Matches any of the values specified in an array.                    |
| $lt      | Matches values that are less than a specified value.                |
| $lte     | Matches values that are less than or equal to a specified value.    |
| $ne      | Matches all values that are not equal to a specified value.         |
| $nin     | Matches none of the values specified in an array.                   |

**Logical Operators**

| Operator | Description                                                                                             |
|----------|---------------------------------------------------------------------------------------------------------|
| $and     | Joins query clauses with a logical AND returns all resources that match the conditions of both clauses. |
| $not     | Inverts the effect of a query expression and returns resources that do not match the query expression.  |
| $or      | Joins query clauses with a logical OR returns all resources that match the conditions of either clause. |

### Example

To uelixirse these operators we simply construct a map using them, below is an example of a valid query.

```elixir
%{
  "$or" => [
    %{"label" => %{"$eq" => "test"}},
    %{"total" => %{"$not" => %{"$gt" => 200}}}
  ],
  "type" => %{"$in" => ["standard", "custom"]}
}
```

### Implicit Operator

When a comparison operator is omitted, the implicit operator is `$eq` which means

```elixir
%{"label" => "test"}
```

is the same as

```elixir
%{"label" => %{"$eq" => "test"}}
```

Similarly, when a logical operator is omitted, the implicit operator is `$and` which means

```elixir
%{"label" => "test", "type" => "standard"}
```

is the same as

```elixir
%{"$and" => [%{"label" => "test"}, %{"type" => "standard"}]}
```

## Permitted Query Fields

It is unlikely the server wants to expose every fields of its resources to the client for query so in order to make the query safe we will need a way to allow the server to specify which fields are permitted. Note that a field of a resource may contain another related resource and we want to allow the query to be able to query on those related resource as well if the server choose to. For example the following can be a perfectly valid query.

```elixir
%{"product.avatar.size" => %{"$gt" => 200}}
```

In essence, when the server execute the query it needs to take in a list of permitted fields in order to safely execute the query like the following:

```elixir
["total", "label", "product.name", "product.avatar.size"]
```

## Ecto Query

A implementation of MonkQL will allow a query be safely transformed to sql queries. In our case it will be ecto queries. In addition to the actual query and the permitted fields there is third piece that we need in order to properly implement MonkQL. A MonkQL query may contain related resources which in SQL world would probably live in a different table, so we will need a way to specify the related table, or in ecto's case the schema.

In essence, the server will also need to take in a mapping of fields to schema like the following

```elixir
%{"product" => Product, "avatar" => File}
```

However just accepting the schema make things quite limited, as there may be cases where we want to filter out some of those related resources before executing the query. For example if a user does not have sufficient privileges to access a item that is inactive then we want to be able to specify that so that even if a inactive item does match it will be treated as if there is no matching one. So instead of providing the schema we should be able to provide a query instead.

```elixir
%{"product" => from(p in Product, where: p.status == "status"), "avatar" => File}
```

## Proposed API Function
```elixir
monkql_query = %{
  "$or" => [
    %{"label" => %{"$eq" => "test"}},
    %{"total" => %{"$not" => %{"$gt" => 200}}}
  ],
  "type" => %{"$in" => ["standard", "custom"]},
  "product.avatar.label" => "promotion",
  "name" => "Name"
}

ecto_query = from(li in LineItem, where: o.status = "confirmed")

permitted_fields = ["label", "total", "product.avatar.label"]

mappings = %{"product" => from(p in Product, where: p.status == "active"), "avatar" => File}

MonkQL.to_ecto_query(ecto_query, monkql_query, permitted_fields, mappings)
```