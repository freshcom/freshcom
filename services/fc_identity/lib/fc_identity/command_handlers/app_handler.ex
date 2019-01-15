defmodule FCIdentity.AppHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCIdentity.AppPolicy

  alias FCIdentity.{AddApp, UpdateApp, DeleteApp}
  alias FCIdentity.{AppAdded, AppUpdated, AppDeleted}
  alias FCIdentity.App

  def handle(%App{id: nil} = state, %AddApp{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%AppAdded{})
    |> unwrap_ok()
  end

  def handle(%App{id: _}, %AddApp{}) do
    {:error, {:already_exist, :app}}
  end

  def handle(%{id: nil}, _), do: {:error, {:not_found, :app}}
  def handle(%{status: "deleted"}, _), do: {:error, {:already_deleted, :app}}

  def handle(state, %UpdateApp{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%AppUpdated{})
    ~> put_original_fields(state)
    |> unwrap_ok()
  end

  def handle(state, %DeleteApp{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%AppDeleted{})
    |> unwrap_ok()
  end
end
