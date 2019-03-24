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
      def authorize(%{account_id: c_aid} = cmd, %{account_id: s_aid}) when (not is_nil(c_aid)) and (not is_nil(s_aid)) and (c_aid != s_aid), do: {:error, :access_denied}
      def authorize(%{client_type: "unkown"}, _), do: {:error, :access_denied}
    end
  end

  def aggregate do
    quote do
      import FCSupport.{Changeset, Struct}

      def put_original_fields(%{effective_keys: ekeys} = event, state) do
        fields = Map.from_struct(state)

        original_fields =
          Enum.reduce(fields, %{}, fn {k, v}, acc ->
            if Enum.member?(ekeys, k) do
              Map.put(acc, k, v)
            else
              acc
            end
          end)

        Map.put(event, :original_fields, original_fields)
      end
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

  def event do
    quote do
      use TypedStruct

      @derive Jason.Encoder
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
