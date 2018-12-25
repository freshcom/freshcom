defmodule Freshcom.MixProject do
  use Mix.Project

  def project do
    [
      app: :freshcom,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      aliases: aliases(),
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {Freshcom.Application, []},
      extra_applications: [:logger],
      included_applications: [
        :fc_identity
      ]
    ]
  end

  defp elixirc_paths(:test), do: ["lib", "test/support"]
  defp elixirc_paths(_), do: ["lib"]

  # Run "mix help deps" to learn about dependencies.
  defp deps do
    [
      {:fc_base, path: "base/fc_base"},
      {:fc_identity, path: "services/fc_identity"},
      {:ecto, "~> 2.1"},
      {:postgrex, "~> 0.13"},
      {:commanded, "~> 0.17"},
      {:commanded_ecto_projections, "~> 0.7"},
      {:inflex, "~> 1.10"},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:faker, "~> 0.11", only: [:test, :dev]}
    ]
  end

  defp aliases do
    [
      "ecto.setup": ["ecto.create", "ecto.migrate"],
      "ecto.reset": ["ecto.drop", "ecto.setup"],
      "event_store.setup": ["event_store.create", "event_store.init"],
      "event_store.reset": ["event_store.drop", "event_store.setup"],
      reset: ["ecto.reset", "event_store.reset"],
      test: ["ecto.create --quiet", "ecto.migrate", "test"]
    ]
  end

  defp docs do
    [
      groups_for_modules: groups_for_modules(),
    ]
  end

  defp groups_for_modules do
    [
      "API Modules": [
        Freshcom.Identity
      ],

      "Request & Response": [
        Freshcom.Request,
        Freshcom.Response
      ],

      "Projections": [
        Freshcom.User,
        Freshcom.App,
        Freshcom.Account,
        Freshcom.RefreshToken
      ],

      "Core": [
        Freshcom.Context,
        Freshcom.Filter,
        Freshcom.Fixture,
        Freshcom.Include,
        Freshcom.Projection,
        Freshcom.Projector,
        Freshcom.Shortcut
      ]
    ]
  end
end
