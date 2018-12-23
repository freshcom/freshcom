# Freshcom

**Fast, scalable and extensible eCommerce backend in Elixir.**

This repo contains the core business logic of the [Freshcom Project](https://github.com/freshcom/freshcom). It provides a Elixir API through 10 [top level modules](https://github.com/freshcom/freshcom) for you to build on top of.

This repo does not include a web layer. Please see [freshcom_web](https://github.com/freshcom/freshcom_web) if you need a web layer that provides a JSON API or simply build your own if you need something other than JSON API.

## Status of Development

Currently a work in progress.

Freshcom is a re-implementation of [Freshcom API](https://github.com/freshcom/freshcom-api) using CQRS/ES.

## Overview

### CQRS/ES

Freshcom uses [commanded](https://github.com/commanded/commanded) and is implemented following the [CQRS/ES](http://cqrs.nu/Faq) pattern. This allows freshcom to take more advantage of OTP and make it much easier to be extended by developers. However, to extend freshcom you do not need to fully understand CQRS/ES, you just need to know that freshcom emits many events in its lifecycle and you can simply act on those event to extend the functionalities.

### Services

Freshcom is built using loosely coupled services where each service is an OTP application. If you do not need to use the complete feature of freshcom or if some feature does not fit your need, you can simply cherry pick the services you need and build the rest on your own.

### I18n

Freshcom provides native support for i18n, each resource can have its attributes saved in unlimited number of locales. You can also easily search against different locales.

### Multi-tenant

Freshcom provide native support for multi-tenant where standard user can create and own multiple accounts.

### Test mode

Freshcom provides native support for test mode. This means you can have test data to run against payment gateway using test mode without effecting your live store or running a different instance.

### Email Templating

Freshcom provides native support for email templating. This means you can customize your email template without redeployment, and each account can have different email template. If you implement a proper front-end you can allow non-developer to easily customize the email for their store.

## Getting Started

### External Dependencies

Currently freshcom requires the following external dependencies to work:

- AWS DynamoDB for (write side) state storage

Our goal is to remove these hard dependencies when we hit beta. If you are not able to use AWS DynamoDB you can also try write your own adapter for state storage. It just need to implement the [FCStateStorage](https://github.com/freshcom/freshcom/blob/master/base/fc_state_storage/lib/fc_state_storage.ex) behaviour and are pretty straight forward to write, take a look at the two default adapaters for reference.

- [FCStateStorage.DynamoAdapter](https://github.com/freshcom/freshcom/blob/master/base/fc_state_storage/lib/fc_state_storage/adapters/dynamo_adapter.ex)
- [FCStateStorage.MemoryAdapter](https://github.com/freshcom/freshcom/blob/master/base/fc_state_storage/lib/fc_state_storage/adapters/memory_adapter.ex)

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

## Learn more

  * Documentation: http://www.comingsoon.io/

## Contact

Any question or feedback feel free to find me in the Elixir Slack Channel @rbao, will usually respond within few hours in PST timezone day time.
