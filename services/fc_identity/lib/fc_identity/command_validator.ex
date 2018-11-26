defmodule FCIdentity.CommandValidator do
  alias FCIdentity.UsernameStore
  alias FCSupport.Validation

  @email_regex ~r/^[A-Za-z0-9'._%+-]+@[A-Za-z0-9.-]+\.[A-Za-z]{2,4}$/
  @username_regex ~r/^[A-Za-z0-9'._%+-@]+$/

  def username(_, cmd) do
    validations = [
      length: [min: 3, max: 120, allow_blank: true],
      format: [with: @username_regex, allow_blank: true],
      by: &unique_username/2
    ]

    case Validation.validate(cmd, username: validations) do
      {:ok, _} ->
        :ok

      {:error, {:validation_failed, [{_, _, error} | _]}} ->
        {:error, error}
    end
  end

  defp unique_username(nil, _), do: :ok

  defp unique_username(username, cmd) do
    user_id = UsernameStore.get(username, Map.get(cmd, :account_id))

    if is_nil(user_id) || user_id == cmd.user_id do
      :ok
    else
      {:error, :taken}
    end
  end

  def email(_, cmd) do
    validations = [
      length: [max: 120],
      format: [with: @email_regex, allow_blank: true]
    ]

    case Validation.validate(cmd, email: validations) do
      {:ok, _} ->
        :ok

      {:error, {:validation_failed, [{_, _, error} | _]}} ->
        {:error, error}
    end
  end
end