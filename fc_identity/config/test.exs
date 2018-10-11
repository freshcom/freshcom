use Mix.Config

config :logger, level: :warn

config :argon2_elixir, t_cost: 1, m_cost: 8

config :eventstore, EventStore.Storage,
  serializer: Commanded.Serialization.JsonSerializer,
  username: System.get_env("DB_USERNAME"),
  database: "fc_identity_eventstore_test",
  hostname: "localhost",
  pool_size: 10

# config :commanded, default_consistency: :strong

# config :fc_identity, FCIdentity.SimpleStore, FCIdentity.DynamoStore

config :fc_identity, FCIdentity.SimpleStore, FCIdentity.MemoryStore