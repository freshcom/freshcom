defmodule FCIdentity.AppHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCIdentity.AppPolicy

  alias FCStateStorage.GlobalStore.AppStore
  alias FCIdentity.{AddApp, DeleteApp}
  alias FCIdentity.{AppAdded, AppDeleted}
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

  def handle(%{id: nil}, _), do: {:error, {:not_found, :app}}
  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :app}}

  def handle(state, %DeleteApp{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%AppDeleted{})
    |> unwrap_ok()
  end

  defp keep_type(%AddApp{} = cmd) do
    AppStore.put(cmd.app_id, cmd.type, cmd.account_id)
    cmd
  end
end