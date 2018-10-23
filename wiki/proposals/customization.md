The goal of the customization system is as follow:

- Allow developer that only want to do minimum customization to do so with minimum effort
- Allow developer that want to replace some part of the system to be able to do so
- Allow developer that only want to use a few part of the system to be able to do so

## Mixin

We should provide a way for developer to add mixins to struct. This provides a easy way for developer to add in fields or validations to commands, events and projections.

Let’s say we want to add a `deparment` field to user related commands, events and projections.

### Command Mixin
```elixir
config :fc_identity, :mixins, %{
  FCIdentity.AddUser: [MyApp.AddUser]
}
```

```elixir
defmodule MyApp.AddUser do
  use FCBase.Mixin.Command

  def fields do
    quote do
      field :department, String.t()
    end
  end

  def validations do
     quote do
       validates :department, presence: true
     end
  end
end
```

### Event Mixin
```elixir
config :fc_identity, :mixins, %{
  FCIdentity.UserAdded: [MyApp.UserAdded]
}
```

```elixir
defmodule MyApp.UserAdded do
  use FCBase.Mixin.Event

  def fields do
    quote do
      field :department, String.t()
    end
  end
end
```

### Projection Mixin
```elixir
config :freshcom, :mixins: %{
  Freshcom.User: [MyApp.User]
}
```

```elixir
defmodule MyApp.User do
  use Freshcom.Mixin.Projection

  def fields do
    quote do
      field :department, :string
    end
  end
end
```

## Middleware

We should provide a way for developer to write their own middleware for command handler, process manager and projector.

### Command Handler Middleware

```elixir
config :fc_identity, :middlewares, %{
  FCIdentity.RegisterUser: [MyApp.UserHandler]
}
```

or


```elixir
config :fc_identity, :middlewares, %{
  FCIdentity.UserHandler: [MyApp.UserHandler]
}
```

```elixir
defmodule MyApp.UserHandler do
  use FCBase.Middleware.CommandHandler

  def before_handle(pipeline) do
    pipeline
  end

  def after_handle(pipeline) do
    pipeline
  end
end
```

### Process Manager Middlware

```elixir
config :fc_identity, :middlewares, %{
  FCIdentity.DefaultAccountSetup: [MyApp.DefaultAccountSetup]
}
```

```elixir
defmodule MyApp.DefaultAccountSetup do
  use FCBase.Middleware.ProcessManager

  def before_handle(pipeline) do
    pipeline
  end

  def after_handle(pipeline) do
    pipeline
  end
end
```

### Projector Middleware

```elixir
config :freshcom, :middlewares, %{
  Freshcom.UserProjection: [MyApp.UserProjection]
}
```

```elixir
defmodule MyApp.UserProjector do
  use Freshcom.Middleware.Projector

  def before_project(pipeline) do
    pipeline
  end

  def after_project(pipeline) do
    pipeline
  end
end
```

## Disabling Event Handler

Plain event handler do not support middleware, if developers want to customize a plain event handler its suggest to disable the default one and implement a custom event handler instead.

```elixir
config :fc_identity, :event_handlers, %{
  except: [FCIdentity.RoleKeeper]
}
```

Note that process manager are also event handlers so you can also use the `:event_handlers` config to disable specific process managers and then implement your own custom process manager.

## Disabling Projector

Projector are also event handlers, however projector are implemented in the top level freshcom app instead of individual services.

```elixir
config :freshcom, :event_handlers, %{
  except: [Freshcom.UserProjector]
}
```

## Using Projection Repo

You can also use the Projection Repo directly, however we do not recommand directly using the projection Repo in your web layer.

```elixir
Freshcom.Repo.all(User)
```
