defmodule FCIdentity.Account do
  use TypedStruct

  import FCIdentity.{Changeset, Support}

  alias FCIdentity.Translation
  alias FCIdentity.{AccountCreated, AccountInfoUpdated}

  typedstruct do
    field :id, String.t()

    field :owner_id, String.t()
    field :mode, String.t(), default: "live"
    field :live_account_id, String.t()
    field :test_account_id, String.t()

    field :name, String.t()
    field :default_locale, String.t()

    field :legal_name, String.t()
    field :website_url, String.t()
    field :support_email, String.t()
    field :tech_email, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map, default: %{}
    field :translations, map, default: %{}
  end

  def translatable_fields do
    [
      :name,
      :company_name,
      :website_url,
      :support_email,
      :tech_email,
      :caption,
      :description,
      :custom_data
    ]
  end

  def apply(%{} = state, %AccountCreated{} = event) do
    %{state | id: event.account_id}
    |> struct_merge(event)
  end

  def apply(%{} = state, %AccountInfoUpdated{locale: locale} = event) do
    state
    |> cast(event, event.effective_keys)
    |> Translation.put_change(translatable_fields(), locale, state.default_locale)
    |> apply_changes()
  end
end