defmodule FCIdentity.UpdateAccountInfo do
  use TypedStruct
  use Vex.Struct

  alias FCIdentity.AccountAliasStore
  alias FCIdentity.CommandValidator
  alias FCIdentity.UpdateAccountInfo

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :effective_keys, [String.t()], default: []
    field :locale, String.t()

    field :alias, String.t()
    field :name, String.t()
    field :legal_name, String.t()
    field :website_url, String.t()
    field :support_email, String.t()
    field :tech_email, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map
  end

  @alias_regex ~r/^[a-zA-Z0-9][a-zA-Z0-9-]+[a-zA-Z0-9]$/

  validates :account_id, presence: true, uuid: true

  validates :alias, presence: true, format: [with: @alias_regex], by: &UpdateAccountInfo.unique_alias/2
  validates :name, presence: true
  validates :support_email, by: &CommandValidator.email/2
  validates :tech_email, by: &CommandValidator.email/2

  def unique_alias(nil, _), do: :ok

  def unique_alias(alius, cmd) do
    account_id = AccountAliasStore.get(alius)

    if is_nil(account_id) || account_id == cmd.account_id do
      :ok
    else
      {:error, :taken}
    end
  end
end
