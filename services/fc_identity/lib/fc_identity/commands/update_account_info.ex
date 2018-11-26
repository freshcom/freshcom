defmodule FCIdentity.UpdateAccountInfo do
  use TypedStruct
  use Vex.Struct

  alias FCIdentity.CommandValidator

  typedstruct do
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :account_id, String.t()

    field :effective_keys, [String.t()], default: []
    field :locale, String.t()

    field :name, String.t()
    field :legal_name, String.t()
    field :website_url, String.t()
    field :support_email, String.t()
    field :tech_email, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map
  end

  validates :account_id, presence: true, uuid: true

  validates :name, presence: true
  validates :support_email, by: &CommandValidator.email/2
  validates :tech_email, by: &CommandValidator.email/2
end
