# Overview

Freshcom is an opinionated eCommerce backend written in Elixir which implements
Command Query Responsibility Segregation and Event Sourcing (CQRS/ES) pattern.

Freshcom provides a solid foundation for you to customize and/or extend to fit your
unique business case. Freshcom is built using loosely coupled services where each
service is an OTP application. It also provides some unique features like built-in
internationalization (i18n), multi-tenant and test mode.

The aim of this introductory guide is to present a brief, high-level overview of Freshcom,
the API module it provides, and the layers underneath that support it.

### Freshcom

Freshcom is made up of a number of distinct API modules, each with its own purpose and
role to play in building a ecommerce application. We will cover them all in depth
throughout these guides, but here's a quick breakdown.

- `Freshcom.Identity`
  - provides functions that deal with identity and access management
  - provides the following resources:
    - `Freshcom.User`
    - `Freshcom.Account`
    - `Freshcom.App`
- `Freshcom.Goods`
  - provides functions that deal with tracking goods that are available
  - provides the following resources:
    - `Freshcom.Stockable` - for goods with stock (ex. t-shirt, coffee or laptop)
    - `Freshcom.Unlockable` - for goods that can only be bought once for a customer (ex. game, audiobook or photo)
    - `Freshcom.Depositable` - for goods that can be deposited (ex. gift card, loyalty points or store credit)
- `Freshcom.Inventory`
  - provides functions that deal with inventory
  - provides the following resources:
    - `Freshcom.Warehouse`
    - `Freshcom.StockBatch`
    - `Freshcom.StockMovement`
- `Freshcom.Catalogue`
  - provides functions that deal with orgnizing and pricing products
  - provides the following resources:
    - `Freshcom.Product`
    - `Freshcom.Price`
    - `Freshcom.ProductCollection`

Test