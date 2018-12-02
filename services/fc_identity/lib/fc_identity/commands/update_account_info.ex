defmodule FCIdentity.UpdateAccountInfo do
  use TypedStruct
  use Vex.Struct

  alias FCIdentity.AccountHandleStore
  alias FCIdentity.CommandValidator
  alias FCIdentity.UpdateAccountInfo

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :effective_keys, [String.t()], default: []
    field :locale, String.t()

    field :handle, String.t()
    field :name, String.t()
    field :legal_name, String.t()
    field :website_url, String.t()
    field :support_email, String.t()
    field :tech_email, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map
  end

  @handle_regex ~r/^[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]$/

  validates :account_id, presence: true, uuid: true

  validates :handle, presence: true, format: [with: @handle_regex], by: &UpdateAccountInfo.unique_handle/2
  validates :name, presence: true
  validates :support_email, by: &CommandValidator.email/2
  validates :tech_email, by: &CommandValidator.email/2

  def unique_handle(nil, _), do: :ok

  def unique_handle(handle, cmd) do
    account_id = AccountHandleStore.get(handle)

    if is_nil(account_id) || account_id == cmd.account_id do
      :ok
    else
      {:error, :taken}
    end
  end
end
