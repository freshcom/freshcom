# JA Ecto Includer

The inclusion of related resources are specified using the include string, which come in JSON API format like so: `line_items.product.prices,customer`.

The goals of the includer are as follow:

- It needs to take in the include string and return a list of queries that can be used to pass in to an Ecto Repo like so `Repo.preload(Include.to_preload(include))`.
- It needs to take in a map of filters, so that the caller can use it to filter specify resources this is needed because when including resources for a requester, it may only have access to a subset of those relate resources.

## API Function

```elixir
include = "lineItems.product.prices,customer"
filters = %{

}


include = "default_price,items.items.prices"
Includer.to_ecto_preload(include, %{})
[
  default_price: {#Ecto.Query<from p in BlueJet.Catalogue.Price,
    where: p.status == ^"active", order_by: [asc: p.minimum_order_quantity]>,
   []},
  items: {#Ecto.Query<from p in BlueJet.Catalogue.Product>,
   [
     items: {#Ecto.Query<from p in BlueJet.Catalogue.Product>,
      [prices: {#Ecto.Query<from p in BlueJet.Catalogue.Price>, []}]}
   ]}
]
```