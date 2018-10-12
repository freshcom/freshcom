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
      {:fc_base, path: "../fc_base"},
      {:commanded, "~> 0.17"},
      {:commanded_eventstore_adapter, "~> 0.3"},
      {:hackney, "~> 1.9"},
      {:comeonin, "~> 4.0"},
      {:argon2_elixir, "~> 1.3"},
      {:faker, "~> 0.11", only: [:test, :dev]},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/freshcom/freshcom/fc_identity",
      groups_for_modules: groups_for_modules()
    ]
  end

  defp groups_for_modules do
    [
      "Commands": [
        FCIdentity.RegisterUser,
        FCIdentity.AddUser,
        FCIdentity.FinishUserRegistration,
        FCIdentity.GeneratePasswordResetToken,

        FCIdentity.CreateAccount,
        FCIdentity.UpdateAccountInfo
      ],

      "Events": [
        FCIdentity.UserAdded,
        FCIdentity.UserRegistered,
        FCIdentity.UserRegistrationRequested,
        FCIdentity.PasswordResetTokenGenerated,

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
