defmodule FCInventory.MixProject do
  use Mix.Project

  def project do
    [
      app: :fc_inevntory,
      name: "Freshcom Inventory",
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env()),
      start_permanent: Mix.env() == :prod,
      deps: deps()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {FCInventory.Application, []},
      extra_applications: [
        :logger,
        :eventstore
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:fc_base, path: "../../base/fc_base"},
      {:commanded, "~> 0.17"},
      {:hackney, "~> 1.9"},
      {:faker, "~> 0.11", only: [:test, :dev]},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false}
    ]
  end
end
