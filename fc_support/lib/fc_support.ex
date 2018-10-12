defmodule FCSupport do
  @moduledoc """
  Documentation for FCSupport.
  """

  def aggregate do
    quote do
      import FCSupport.{Changeset, Struct}

      alias FCSupport.Translation
    end
  end

  def command_handler do
    quote do
      use OK.Pipe

      import FCSupport.{ControlFlow, Struct}

      alias FCSupport.Translation
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
