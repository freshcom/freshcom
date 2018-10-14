defmodule Freshcom.Router do
  use Commanded.Commands.CompositeRouter

  router FCIdentity.Router
end