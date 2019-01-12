use Mix.Config

config :ex_unit, capture_log: true

config :argon2_elixir, t_cost: 1, m_cost: 8

config :eventstore, EventStore.Storage,
  serializer: Commanded.Serialization.JsonSerializer,
  username: System.get_env("DB_USERNAME"),
  database: "fc_goods_eventstore_test",
  hostname: "localhost",
  pool_size: 10

config :logger, level: :warn

config :fc_state_storage, adapter: FCStateStorage.MemoryAdapter