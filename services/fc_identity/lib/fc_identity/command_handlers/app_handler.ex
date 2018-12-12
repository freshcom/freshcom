defmodule FCIdentity.AppHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCIdentity.AppPolicy

  alias FCStateStorage.GlobalStore.AppTypeStore
  alias FCIdentity.{AddApp}
  alias FCIdentity.{AppAdded}
  alias FCIdentity.App

  def handle(%App{id: nil} = state, %AddApp{} = cmd) do
    cmd
    |> authorize(state)
    ~> keep_type()
    ~> merge_to(%AppAdded{})
    |> unwrap_ok()
  end

  def handle(%App{id: _}, %AddApp{}) do
    {:error, {:already_exist, :app}}
  end

  defp keep_type(%AddApp{} = cmd) do
    AppTypeStore.put(cmd.app_id, cmd.type, cmd.account_id)
    cmd
  end
end