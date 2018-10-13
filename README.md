# Freshcom

**Fast, scalable and extensible eCommerce backend in Elixir.**

_Note: Freshcom does not include a web layer. Please see [Freshcom Web](https://github.com/freshcom/freshcom-api) if you need a web layer._

## Status of development

Currently a work in progress.

Freshcom is a re-implementation of [Freshcom API](https://github.com/freshcom/freshcom-api) using CQRS/ES.

## Overview

### CQRS/ES

Freshcom uses [commanded](https://github.com/commanded/commanded) and is implemented following the [CQRS/ES](http://cqrs.nu/Faq) pattern. This allows freshcom to take more advantage of OTP and make it much easier to be extended by developers. However, to extend freshcom you do not need to fully understand CQRS/ES, you just need to know that freshcom emits many events in its lifecycle and you can simply act on those event to extend the functionalities.

### Services

Freshcom is built using loosely coupled services where each service is an OTP application. If you do not need to use the complete feature of Freshcom or if some feature does not fit your need, you can simply cherry pick the services you need and build the rest on your own.

### I18n

Freshcom provides native support for I18n, each resource can have its attributes saved in unlimited number of locales. You can also easily search against different locales.

### Multi-tenant

Freshcom provide native support for multi-tenant where standard user can create and own multiple accounts (similar to Stripe).

### Test mode

Freshcom provides native support for test mode (similar Stripe). This means you can have test data to run against payment gateway using test mode without effecting your live store or running a different instance.

### Email Templating

Freshcom provides native support for email templating. This means you can customize your email template without redeployment, and each account can have different email template. If you implement a proper front-end you can allow non-developer to easily customize the email for their store.
