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

      defimpl Inspect do
        @identity_keys [
          :requester_id,
          :requester_type,
          :requester_role,
          :client_id,
          :client_type
        ]

        def inspect(%{__struct__: t, __version__: v} = event, opts) do
          map =
            event
            |> Map.drop([:__struct__, :__version__])
            |> clean_identity_fields()
            |> clean_effective_keys()

          name = Inspect.Algebra.to_doc(t, opts) <> "#v#{v}"
          Inspect.Map.inspect(map, name, opts)
        end

        defp clean_identity_fields(%{requester_role: "system"} = map) do
          Map.drop(map, @identity_keys -- [:requester_role])
        end

        defp clean_identity_fields(%{requester_role: nil, requester_id: nil, requester_type: nil} = map) do
          Map.drop(map, @identity_keys)
        end

        defp clean_identity_fields(map), do: map

        defp clean_effective_keys(%{effective_keys: ekeys} = map) do
          ekeys = ekeys ++ @identity_keys ++ [:locale, :original_fields]
          dkeys = Map.keys(map) -- ekeys
          Map.drop(map, dkeys)
        end

        defp clean_effective_keys(map), do: map
      end
    end
  end

  defmacro __using__(which) when is_atom(which) do
    apply(__MODULE__, which, [])
  end
end
