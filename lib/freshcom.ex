defmodule Freshcom do
  def api_module do
    quote do
      use OK.Pipe

      import Freshcom.APIModule

      alias Freshcom.{Repo, Projector, APIModule, Request}
    end
  end

  def policy do
    quote do
      @admin_roles ["owner", "administrator"]
      @dev_roles @admin_roles ++ ["developer"]
      @customer_management_roles @dev_roles ++ ["manager", "support_specialist"]
      @operator_roles @customer_management_roles ++ ["marketing_specialist", "goods_specialist", "read_only"]
      @guest_roles @operator_roles ++ ["guest"]

      def authorize(%{_role_: "sysdev"} = req, _), do: {:ok, req}
      def authorize(%{_role_: "system"} = req, _), do: {:ok, req}
      def authorize(%{_role_: "appdev"} = req, _), do: {:ok, req}
      def authorize(%{_client_: nil}, _), do: {:error, :access_denied}
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
