defmodule FCIdentity.AppHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCIdentity.AppPolicy

  alias FCIdentity.{AddApp}
  alias FCIdentity.{AppAdded}
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
end