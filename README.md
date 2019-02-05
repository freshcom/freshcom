# Freshcom

[![Build Status](https://travis-ci.org/freshcom/freshcom.svg?branch=master)](https://travis-ci.org/freshcom/freshcom)

**Fast, scalable and extensible eCommerce backend in Elixir.**

Please see an overview of freshcom [here](https://github.com/freshcom/freshcom/blob/master/guides/introduction/overview.md).

## Getting Started

### External Dependencies

Freshcom requires the following external dependencies to work:

- Postgres for event store and projections
- Redis for write side state storage

### Setup

#### 1. Install Mix Depedencies

```
$ git clone https://github.com/freshcom/freshcom
$ cd freshcom
$ mix deps.get
```

#### 2. Set Environment Variables

Once all the mix dependencies are installed we need to config the environment variables. Please copy paste `.env.example` and rename it to `.env` add in all the relevant environment variables. Then run `source .env` to set all the variables.

#### 3. Setup Database

Setup the database with `mix freshcom.setup` which will do the following for you:

- Create the projection (read side) database and run all the relevant migrations
- Create and initialize the eventstore (write side) database

### Run

Once you have everything setup you can get into iex with `iex -S mix` and try calling functions on the top level modules to see if things works properly. For example to create a user:

```elixir
req = %Request{
  fields: %{
    "name" => "Demo User",
    "username" => "test@example.com",
    "email" => "test@example.com",
    "password" => "test1234",
    "is_term_accepted" => true
  },
  _role_: "system"
}

{:ok, %{data: user}} = Freshcom.Identity.register_user(req)
```

## Roadmap

### Base

- [x] Filter
- [x] Include
- [x] Pagination
- [x] I18N
- [x] Search
- [x] Sort
- [x] Store
- [x] Validation

### Services

- [x] Identity (Completed)
- [ ] Goods (In Progress) (30%)
- [ ] Inventory
- [ ] Catalogue
- [ ] CRM
- [ ] Finance
- [ ] Storefront
- [ ] Fulfillment
- [ ] Notification

## Learn more

  * Documentation: http://www.comingsoon.io/

## Contact

Any question or feedback feel free to find me in the Elixir Slack Channel @rbao, will usually respond within few hours in PST timezone day time.
