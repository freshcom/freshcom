defmodule Freshcom.Router do
  @moduledoc false

  use Commanded.Commands.CompositeRouter

  router FCIdentity.Router
end