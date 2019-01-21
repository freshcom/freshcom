defmodule FCBase.Fixture do
  import UUID
  alias FCStateStorage.GlobalStore.{UserRoleStore, UserTypeStore, AppStore}

  def user_id(account_id, role) do
    requester_id = uuid4()
    UserRoleStore.put(requester_id, account_id, role)

    if role == "owner" do
      UserTypeStore.put(requester_id, "standard")
    else
      UserTypeStore.put(requester_id, "managed")
    end

    requester_id
  end

  def app_id(type, account_id \\ nil) do
    app_id = uuid4()
    AppStore.put(app_id, type, account_id)

    app_id
  end
end