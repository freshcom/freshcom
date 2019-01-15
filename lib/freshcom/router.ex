defmodule Freshcom.Router do
  @moduledoc false

  use Commanded.Commands.CompositeRouter

  router(FCIdentity.Router)
  router(FCGoods.Router)
end
