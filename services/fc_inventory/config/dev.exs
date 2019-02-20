use Mix.Config

config :eventstore, EventStore.Storage,
  serializer: FCBase.EventSerializer,
  username: System.get_env("EVENTSTORE_DB_USERNAME"),
  password: System.get_env("EVENTSTORE_DB_PASSWORD"),
  database: "fc_inventory_eventstore_dev",
  hostname: "localhost",
  pool_size: 10

config :fc_state_storage, :adapter, FCStateStorage.RedisAdapter
config :fc_state_storage, :redis, System.get_env("REDIS_URL")
