defmodule Freshcom.IntegrationCase do
  use ExUnit.CaseTemplate

  using do
    quote do
      import Freshcom.IntegrationCase

      alias Freshcom.Request
    end
  end

  setup tags do
    :ok = Ecto.Adapters.SQL.Sandbox.checkout(Freshcom.Repo)
    unless tags[:async] do
      Ecto.Adapters.SQL.Sandbox.mode(Freshcom.Repo, {:shared, self()})
    end

    {:ok, _} = Application.ensure_all_started(:freshcom)

    on_exit(fn ->
      :ok = Application.stop(:commanded)

      FCBase.EventStore.reset!()
    end)

    :ok
  end
end