use Mix.Config

config :commanded,
  event_store_adapter: Commanded.EventStore.Adapters.EventStore,
  pubsub: [
    phoenix_pubsub: [
      adapter: Phoenix.PubSub.PG2,
      pool_size: 1
    ]
  ]

import_config "#{Mix.env()}.exs"