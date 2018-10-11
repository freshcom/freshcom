defmodule FCIdentity.MixProject do
  use Mix.Project

  def project do
    [
      app: :fc_identity,
      version: "0.1.0",
      elixir: "~> 1.7",
      elixirc_paths: elixirc_paths(Mix.env),
      start_permanent: Mix.env() == :prod,
      deps: deps(),
      docs: docs()
    ]
  end

  # Run "mix help compile.app" to learn about applications.
  def application do
    [
      mod: {FCIdentity.Application, []},
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
      {:commanded, "~> 0.17"},
      {:commanded_eventstore_adapter, "~> 0.3"},
      {:vex, "~> 0.7"},
      {:typed_struct, "~> 0.1"},
      {:ex_aws, "~> 2.1"},
      {:ex_aws_dynamo, "~> 2.0"},
      {:hackney, "~> 1.9"},
      {:comeonin, "~> 4.0"},
      {:argon2_elixir, "~> 1.3"},
      {:ok, "~> 2.0"},
      {:faker, "~> 0.11", only: [:test, :dev]},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
      # {:dep_from_hexpm, "~> 0.3.0"},
      # {:dep_from_git, git: "https://github.com/elixir-lang/my_dep.git", tag: "0.1.0"},
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/rbao/fc_identity",
      groups_for_modules: groups_for_modules()
    ]
  end

  defp groups_for_modules do
    [
      "Commands": [
        FCIdentity.RegisterUser,
        FCIdentity.AddUser,
        FCIdentity.FinishUserRegistration,

        FCIdentity.CreateAccount,
        FCIdentity.UpdateAccountInfo
      ],

      "Events": [
        FCIdentity.UserAdded,
        FCIdentity.UserRegistered,
        FCIdentity.UserRegistrationRequested,
        FCIdentity.AccountCreated,
        FCIdentity.AccountInfoUpdated,
      ],

      "Support": [
        FCIdentity.Changeset,
        FCIdentity.Normalization,
        FCIdentity.Translation,
        FCIdentity.Validation,
        FCIdentity.Support
      ]
    ]
  end
end
