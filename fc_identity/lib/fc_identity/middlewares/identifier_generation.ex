defmodule FCIdentity.IdentifierGeneration do
  @behaviour Commanded.Middleware

  alias Commanded.Middleware.Pipeline

  def before_dispatch(%Pipeline{} = pipeline) do
    generate(pipeline)
  end

  def generate(%{command: cmd, identity: identity} = pipeline) do
    identity_value = Map.get(cmd, identity)

    if is_nil(identity_value) do
      cmd = Map.put(cmd, identity, UUID.uuid4())
      %{pipeline | command: cmd}
    else
      pipeline
    end
  end

  def after_dispatch(pipeline), do: pipeline
  def after_failure(pipeline), do: pipeline
end