defmodule FCIdentity.UserHandler do
  @behaviour Commanded.Commands.Handler

  use OK.Pipe

  import Comeonin.Argon2
  import FCIdentity.{Support, Validation, Normalization}
  import FCIdentity.UserPolicy

  alias FCIdentity.UsernameKeeper
  alias FCIdentity.{RegisterUser, AddUser, DeleteUser}
  alias FCIdentity.{
    UserRegistrationRequested,
    FinishUserRegistration,
    UserAdded,
    UserRegistered,
    UserDeleted
  }

  def handle(%{id: nil} = state, %RegisterUser{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%UserRegistrationRequested{})
    |> unwrap_ok()
  end

  def handle(_, %RegisterUser{}), do: {:error, {:already_registered, :user}}

  def handle(%{id: nil} = state, %AddUser{} = cmd) do
    cmd
    |>  authorize(state)
    ~>  trim_strings()
    ~>  downcase_strings([:username, :email])
    ~>  put_name()
    ~>> validate(name: [presence: true])
    ~>> validate_username()
    ~>  merge_to(%UserAdded{type: cmd._type_})
    ~>  put_password_hash(cmd)
    |>  unwrap_ok()
  end

  def handle(_, %AddUser{}), do: {:error, {:already_exist, :user}}

  def handle(%{id: nil}, _), do: {:error, {:not_found, :user}}

  def handle(%{id: user_id} = state, %FinishUserRegistration{} = cmd) do
    %UserRegistered{
      user_id: user_id,
      default_account_id: state.account_id,
      username: state.username,
      password_hash: state.password_hash,
      email: state.email,
      is_term_accepted: cmd.is_term_accepted,
      first_name: state.first_name,
      last_name: state.last_name,
      name: state.name
    }
  end

  def handle(state, %DeleteUser{} = cmd) do
    cmd
    |> authorize(state)
    ~> merge_to(%UserDeleted{})
    |> unwrap_ok()
  end

  defp put_name(%{name: name} = cmd) when byte_size(name) > 0 do
    cmd
  end

  defp put_name(cmd) do
    name = String.trim("#{cmd.first_name} #{cmd.last_name}")
    %{cmd | name: name}
  end

  defp validate_username(cmd) do
    unless UsernameKeeper.exist?(cmd.username) do
      {:ok, cmd}
    else
      {:error, {:validation_failed, [{:error, :username, :already_exist}]}}
    end
  end

  defp put_password_hash(event, %{password: password}) when byte_size(password) > 0 do
    %{event | password_hash: hashpwsalt(password)}
  end

  defp put_password_hash(event, _), do: event
end