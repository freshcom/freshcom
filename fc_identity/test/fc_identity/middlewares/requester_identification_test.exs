defmodule FCIdentity.RequesterIdentificationTest do
  use FCIdentity.UnitCase, async: true

  alias FCStateStorage.GlobalStore.RoleStore
  alias FCIdentity.TypeStore
  alias FCIdentity.RequesterIdentification
  alias FCIdentity.DummyCommand

  describe "identify/1" do
    test "when requester role is already set should not be set again" do
      original_cmd = %DummyCommand{requester_role: :sysdev}
      cmd = RequesterIdentification.identify(original_cmd)

      assert cmd.requester_role == cmd.requester_role
    end

    test "when requester role not set and account id is nil role should be anonymous" do
      original_cmd = %DummyCommand{requester_role: nil, account_id: nil}
      cmd = RequesterIdentification.identify(original_cmd)

      assert cmd.requester_role == "anonymous"
    end

    test "when requester role not set and requester id is nil role should be guest" do
      original_cmd = %DummyCommand{requester_role: nil, account_id: uuid4()}
      cmd = RequesterIdentification.identify(original_cmd)

      assert cmd.requester_role == "guest"
    end

    test "when requester role not set and user id is provided" do
      user_id = uuid4()
      account_id = uuid4()
      RoleStore.put(user_id, account_id, "developer")
      TypeStore.put(user_id, "standard")

      original_cmd = %DummyCommand{
        requester_id: user_id,
        requester_role: nil,
        account_id: account_id
      }
      cmd = RequesterIdentification.identify(original_cmd)

      assert cmd.requester_role == "developer"
      assert cmd.requester_type == "standard"
    end
  end
end