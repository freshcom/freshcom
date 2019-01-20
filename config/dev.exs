use Mix.Config

config :logger, level: :warn

config :eventstore, EventStore.Storage,
  serializer: Commanded.Serialization.JsonSerializer,
  username: System.get_env("EVENTSTORE_DB_USERNAME"),
  password: System.get_env("EVENTSTORE_DB_PASSWORD"),
  database: "freshcom_eventstore_dev",
  hostname: "localhost",
  pool_size: 10

config :fc_state_storage, :adapter, FCStateStorage.RedisAdapter
config :fc_state_storage, :redis, System.get_env("REDIS_URL")

config :freshcom, Freshcom.Repo,
  adapter: Ecto.Adapters.Postgres,
  database: "freshcom_projections_dev",
  hostname: "localhost",
  username: System.get_env("PROJECTION_DB_USERNAME"),
  password: System.get_env("PROJECTION_DB_PASSWORD"),
  pool_size: 10
