defmodule FCIdentity.UserTest do
  use FCIdentity.UnitCase, async: true

  alias FCIdentity.User
  alias FCIdentity.UserAdded

  test "apply UserAdded" do
    event = %UserAdded{
      user_id: uuid4(),
      account_id: uuid4(),
      username: Faker.String.base64(8),
      password_hash: Faker.String.base64(24),
      email: Faker.Internet.email(),
      name: Faker.Name.name()
    }

    user = User.apply(%User{}, event)

    assert user.id == event.user_id
    assert user.account_id == event.account_id
    assert user.username == event.username
    assert user.email == event.email
    assert user.name == event.name
  end
end