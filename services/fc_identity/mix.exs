defmodule FCIdentity.MixProject do
  use Mix.Project

  def project do
    [
      app: :fc_identity,
      name: "Freshcom Identity",
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
      {:fc_base, path: "../../base/fc_base"},
      {:hackney, "~> 1.9"},
      {:comeonin, "~> 4.0"},
      {:argon2_elixir, "~> 1.3"},
      {:faker, "~> 0.11", only: [:test, :dev]},
      {:ex_doc, "~> 0.19", only: :dev, runtime: false},
      {:dialyxir, "~> 1.0.0-rc.3", only: [:dev], runtime: false}
    ]
  end

  defp docs do
    [
      source_url: "https://github.com/freshcom/freshcom/fc_identity",
      groups_for_modules: groups_for_modules(),
      extras: ["README.md"],
      main: "readme"
    ]
  end

  defp groups_for_modules do
    [
      "Commands": [
        FCIdentity.AddUser,
        FCIdentity.ChangePassword,
        FCIdentity.ChangeUserRole,
        FCIdentity.DeleteUser,
        FCIdentity.FinishUserRegistration,
        FCIdentity.GenerateEmailVerificationToken,
        FCIdentity.GeneratePasswordResetToken,
        FCIdentity.RegisterUser,
        FCIdentity.UpdateUserInfo,
        FCIdentity.VerifyEmail,

        FCIdentity.CreateAccount,
        FCIdentity.UpdateAccountInfo
      ],

      "Events": [
        FCIdentity.EmailVerificationTokenGenerated,
        FCIdentity.EmailVerified,
        FCIdentity.PasswordChanged,
        FCIdentity.PasswordResetTokenGenerated,
        FCIdentity.UserAdded,
        FCIdentity.UserDeleted,
        FCIdentity.UserInfoUpdated,
        FCIdentity.UserRegistered,
        FCIdentity.UserRegistrationRequested,
        FCIdentity.UserRoleChanged,

        FCIdentity.AccountCreated,
        FCIdentity.AccountInfoUpdated,
      ],

      "Stores": [
        FCIdentity.UsernameStore
      ]
    ]
  end
end
