defmodule FCIdentity.CommandValidation do
  @behaviour Commanded.Middleware

  alias Commanded.Middleware.Pipeline
  alias FCIdentity.Validation

  def before_dispatch(%Pipeline{} = pipeline) do
    validate(pipeline)
  end

  def validate(%{command: %{effective_keys: e_keys} = cmd, identity: identity} = pipeline) do
    e_keys = e_keys ++ [identity]

    cmd
    |> Validation.validate(effective_keys: e_keys)
    |> put_validation_result(pipeline)
  end

  def validate(%{command: cmd} = pipeline) do
    cmd
    |> Validation.validate()
    |> put_validation_result(pipeline)
  end

  defp put_validation_result({:ok, _}, pipeline) do
    pipeline
  end

  defp put_validation_result({:error, reason}, pipeline) do
    pipeline
    |> Pipeline.respond({:error, reason})
    |> Pipeline.halt()
  end

  def after_dispatch(pipeline), do: pipeline
  def after_failure(pipeline), do: pipeline
end