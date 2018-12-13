defmodule Mix.Tasks.Freshcom.Demo do
  use Mix.Task

  alias Freshcom.Request
  alias Freshcom.Identity

  def run(_) do
    Application.ensure_all_started(:freshcom)

    req = %Request{
      fields: %{
        "name" => "Demo User",
        "username" => "test@example.com",
        "email" => "test@example.com",
        "password" => "test1234",
        "is_term_accepted" => true
      },
      _role_: "system"
    }

    {:ok, _} = Identity.register_user(req)

    req = %Request{
      fields: %{
        "type" => "system",
        "name" => "Freshcom Dashboard"
      },
      _role_: "system"
    }

    {:ok, _} = Identity.add_app(req)
  end
end