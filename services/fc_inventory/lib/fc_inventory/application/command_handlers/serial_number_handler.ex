defmodule FCInventory.SerialNumberHandler do
  @moduledoc false

  @behaviour Commanded.Commands.Handler

  use FCBase, :command_handler

  import FCInventory.SerialNumberPolicy

  alias FCInventory.{AddSerialNumber}
  alias FCInventory.{SerialNumberAdded}

  def handle(state, %AddSerialNumber{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%SerialNumberAdded{})
    |> unwrap_ok()
  end
end
