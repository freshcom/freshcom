use Mix.Config

config :eventstore, EventStore.Storage,
  serializer: Commanded.Serialization.JsonSerializer,
  username: System.get_env("DB_USERNAME"),
  database: "fc_goods_eventstore_dev",
  hostname: "localhost",
  pool_size: 10

config :fc_state_storage, adapter: FCStateStorage.DynamoAdapter