defmodule Freshcom do
  def api_module do
    quote do
      use OK.Pipe

      import Freshcom.APIModule

      alias Freshcom.{Repo, Projector, APIModule, Request}
      alias Freshcom.Repo
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
