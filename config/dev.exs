use Mix.Config

config :logger, level: :warn

config :eventstore, EventStore.Storage,
  serializer: Commanded.Serialization.JsonSerializer,
  username: System.get_env("DB_USERNAME"),
  database: "freshcom_eventstore_dev",
  hostname: "localhost",
  pool_size: 10

config :fc_state_storage, adapter: FCStateStorage.DynamoAdapter

config :freshcom, Freshcom.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "freshcom_projections_dev",
  hostname: "localhost",
  username: System.get_env("DB_USERNAME"),
  pool_size: 10

config :commanded_ecto_projections,
  repo: Freshcom.Repo