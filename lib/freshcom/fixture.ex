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
      include: opts[:include]
    }

    {:ok, %{data: user}} = Identity.register_user(req)

    user
  end

  def managed_user(account_id) do
    req = %Request{
      account_id: account_id,
      fields: %{
        "username" => Internet.user_name(),
        "role" => "developer",
        "password" => "test1234"
      },
      _role_: "system"
    }

    {:ok, %{data: user}} = Identity.add_user(req)

    user
  end
end