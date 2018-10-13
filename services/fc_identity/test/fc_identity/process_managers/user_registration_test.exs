defmodule FCidentity.UserRegistrationTest do
  use FCIdentity.UnitCase, async: true

  alias FCIdentity.UserRegistration
  alias FCIdentity.{
    UserRegistrationRequested,
    AddUser,
    CreateAccount
  }

  test "handle UserRegistrationRequested" do
    cmd = %UserRegistrationRequested{
      user_id: uuid4(),
      username: Faker.String.base64(12),
      password: Faker.String.base64(12),
      email: Faker.Internet.email(),
      is_term_accepted: true,
      name: Faker.Name.name(),
      account_name: Faker.Company.name(),
      default_locale: "zh-CN"
    }

    [%CreateAccount{} = cla, %CreateAccount{} = cta, %AddUser{} = au] = UserRegistration.handle(%{}, cmd)

    assert cla.account_id
    assert cla.name == cmd.account_name
    assert cla.owner_id == cmd.user_id
    assert cla.mode == "live"
    assert cla.test_account_id
    assert cla.default_locale == cmd.default_locale

    assert cta.account_id
    assert cta.name == cmd.account_name
    assert cta.owner_id == cmd.user_id
    assert cta.mode == "test"
    assert cta.live_account_id
    assert cta.default_locale == cmd.default_locale

    assert au._type_ == "standard"
    assert au.requester_role == "system"
    assert au.account_id == cla.account_id
    assert au.status == "pending"
    assert au.role == "owner"
  end
end