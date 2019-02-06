defmodule FCIdentity.AccountCreated do
  use TypedStruct

  @derive Jason.Encoder
  @version 1

  typedstruct do
    field :__version__, integer(), default: @version

    field :request_id, String.t()
    field :requester_id, String.t()
    field :requester_type, String.t()
    field :requester_role, String.t()
    field :client_id, String.t()
    field :client_type, String.t()
    field :account_id, String.t()

    field :status, String.t(), default: "active"
    field :system_label, String.t()
    field :owner_id, String.t()
    field :mode, String.t()
    field :live_account_id, String.t()
    field :test_account_id, String.t()

    field :handle, String.t()
    field :name, String.t()
    field :default_locale, String.t()

    field :custom_data, map(), default: %{}
    field :translations, map(), default: %{}
  end
end
