defmodule FCBase do
  def policy do
    quote do
      import FCBase.Policy

      @admin_roles ["owner", "administrator"]
      @dev_roles @admin_roles ++ ["developer"]
      @customer_management_roles @dev_roles ++ ["manager", "support_specialist"]
      @goods_management_roles @dev_roles ++ ["manager", "goods_specialist"]

      def authorize(%{requester_role: "sysdev"} = cmd, _), do: {:ok, cmd}
      def authorize(%{requester_role: "system"} = cmd, _), do: {:ok, cmd}
      def authorize(%{requester_role: "appdev"} = cmd, _), do: {:ok, cmd}
      def authorize(%{client_type: "unkown"}, _), do: {:error, :access_denied}
    end
  end

  def aggregate do
    quote do
      import FCSupport.{Changeset, Struct}
    end
  end

  def command_handler do
    quote do
      use OK.Pipe

      import FCSupport.{ControlFlow, Struct}
      import FCBase.CommandHandler

      alias FCSupport.Translation
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
