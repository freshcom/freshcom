# Overview

Freshcom is an opinionated eCommerce backend written in Elixir which implements
Command Query Responsibility Segregation and Event Sourcing (CQRS/ES) pattern.
The goal of freshcom is to be fast, scalable and extensible.

Freshcom provides a solid foundation for you to customize and/or extend to fit your
unique business case. Freshcom is built using loosely coupled services where each
service is an OTP application. It also provides some unique features like built-in
internationalization (i18n), multi-tenant and test mode.

It is important to note that freshcom itself does not include any web layer. It only
provides a Elixir API through its API modules. if you need a off-the-shelf web layer
that provides a JSON API please checkout [Freshcom JSONAPI](https://github.com/freshcom/freshcom_web)
which builds on top of freshcom.

The aim of this introductory guide is to present a brief, high-level overview of freshcom,
the API module it provides, and the layers underneath that support it.

## API Modules

Freshcom is made up of a number of distinct API modules, each provides a few resources
with its own purpose in building a ecommerce application. We will cover them all
in depth throughout these guides, but here's a quick breakdown.

- [Identity](Freshcom.Identity.html)
  - `Freshcom.User`
  - `Freshcom.Account`
  - `Freshcom.App`
- [Goods](Freshcom.Goods.html)
  - `Freshcom.Stockable`
  - `Freshcom.Unlockable`
  - `Freshcom.Depositable`
- [Inventory](Freshcom.Inventory.html)
  - `Freshcom.Warehouse`
  - `Freshcom.StockBatch`
  - `Freshcom.StockMovement`
- [Catalogue](Freshcom.Catalogue.html)
  - `Freshcom.Product`
  - `Freshcom.Price`
  - `Freshcom.ProductCollection`
- [CRM](Freshcom.CRM.html)
  - `Freshcom.Customer`
  - `Freshcom.PointAccount`
  - `Freshcom.PointTransaction`
- [Finance](Freshcom.Finance.html)
  - `Freshcom.Payment`
  - `Freshcom.Refund`
  - `Freshcom.Card`
  - `Freshcom.Payout`
- [Storefront](Freshcom.Storefront.html)
  - `Freshcom.Order`
  - `Freshcom.OrderLineItem`
- [Fulfillment](Freshcom.Fulfillment.html)
  - `Freshcom.FulfillmentPackage`
  - `Freshcom.FulfillmentLineItem`
  - `Freshcom.ReturnPackage`
  - `Freshcom.ReturnLineItem`
- [Notification](Freshcom.Notification.html)
  - `Freshcom.NotificationTrigger`
  - `Freshcom.EmailTemplate`
  - `Freshcom.SMSTemplate`

## Layers

We just covered the API (public) modules that make up freshcom, but its important to
remember freshcom itself is actually the top layer of a multi-layer system designed
to be modular and flexible. The layers can be illustrated with the diagram below.

<img alt="Layers Diagram" src="images/introduction/layers.png" width="1022px">

### Application Layer

The application layer includes the read side and consolidates everything into API
modules for you to conveniently call upon. Any API module's function that mutates
states is not directly processed in this layer, instead the request gets translated
into a command and gets dispatched to its corresponding service layer for processing.
This layer then listens for service layer event and project interested resources into
projection database using [ecto](https://github.com/elixir-ecto/ecto) for later reading.

### Service Layer

The service layer includes the write side and emits event when something interesting
happens. The write side of each API module is actually a seperate mix project which
we refer them as "service". You can see a list of services that
is underneath freshcom [here](https://github.com/freshcom/freshcom/tree/master/services).
Each service is built using [commanded](https://github.com/commanded/commanded)
which is a Elixir framework for building CQRS/ES applications.

## The Freshcom Project

Freshcom is the core library of the [Freshcom Project](https://github.com/freshcom),
however the Freshcom Project include a few other library that can help you get
started faster if you are looking for a Web API Backend + Single Page Application (SPA)
Frontend solution:

- [Freshcom JSONAPI](https://github.com/freshcom/freshcom_web) is a phoenix API only application
that builds on top of freshcom and provides a JSON API.

- [Freshcom Dashboard](https://github.com/freshcom/freshcom_dashboard) is a VueJS application
that connects to Freshcom JSONAPI and provides you a UI with back office functionalities.