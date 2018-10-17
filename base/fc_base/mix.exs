defmodule FCBase.MixProject do
  use Mix.Project

  def project do
    [
      app: :fc_base,
      version: "0.1.0",
      elixir: "~> 1.7",
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      extra_applications: [:logger]
    ]
  end

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:fc_support, path: "../fc_support"},
      {:fc_state_storage, path: "../fc_state_storage"},
      {:commanded, "~> 0.17"},
      {:commanded_eventstore_adapter, "~> 0.3"},
      {:phoenix_pubsub, "~> 1.1"},
      {:ok, "~> 2.0"}
    ]
  end
end
