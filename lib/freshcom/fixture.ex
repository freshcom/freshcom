defmodule Freshcom.Fixture do
  alias Faker.{Internet, Name}
  alias Freshcom.{Request, Identity}

  def standard_user(opts \\ []) do
    req = %Request{
      fields: %{
        name: Name.name(),
        username: Internet.user_name(),
        email: Internet.email(),
        password: "test1234",
        is_term_accepted: true
      },
      include: opts[:include],
      _role_: "system"
    }

    {:ok, %{data: user}} = Identity.register_user(req)

    user
  end

  def managed_user(account_id, fields \\ []) do
    req = %Request{
      account_id: account_id,
      fields: %{
        "username" => fields[:username] || Internet.user_name(),
        "role" => fields[:role] || "developer",
        "password" => fields[:password] || "test1234"
      },
      _role_: "system"
    }

    {:ok, %{data: user}} = Identity.add_user(req)

    user
  end

  def standard_app(account_id) do
    req = %Request{
      account_id: account_id,
      fields: %{
        "type" => "standard",
        "name" => "Standard App",
      },
      _role_: "system"
    }

    {:ok, %{data: app}} = Identity.add_app(req)

    app
  end

  def system_app() do
    req = %Request{
      fields: %{
        "type" => "system",
        "name" => "System App"
      },
      _role_: "system"
    }

    {:ok, %{data: app}} = Identity.add_app(req)

    app
  end
end