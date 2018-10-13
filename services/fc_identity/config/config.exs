use Mix.Config

config :commanded,
  event_store_adapter: Commanded.EventStore.Adapters.EventStore

config :ex_aws, region: System.get_env("AWS_REGION")

config :ex_aws, :retries,
  max_attempts: 3,
  base_backoff_in_ms: 10,
  max_backoff_in_ms: 10_000

config :fc_identity, :email_regex, ~r/^[A-Za-z0-9._%+-+']+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/

import_config "#{Mix.env()}.exs"
