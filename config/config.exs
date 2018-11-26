use Mix.Config

config :commanded,
  event_store_adapter: Commanded.EventStore.Adapters.EventStore,
  pubsub: [
    phoenix_pubsub: [
      adapter: Phoenix.PubSub.PG2,
      pool_size: 1
    ]
  ]

config :commanded_ecto_projections,
  repo: Freshcom.Repo

config :ex_aws, region: System.get_env("AWS_REGION")

config :ex_aws, :retries,
  max_attempts: 3,
  base_backoff_in_ms: 10,
  max_backoff_in_ms: 10_000

config :freshcom,
  ecto_repos: [Freshcom.Repo]

config :freshcom,
  pubsub: [
    adapter: Phoenix.PubSub.PG2,
    pool_size: 1,
    name: Freshcom.PubSubServer
  ]

import_config "#{Mix.env()}.exs"