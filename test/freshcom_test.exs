defmodule FreshcomTest do
  use Freshcom.IntegrationCase

  describe "register_user/1" do
    test "with invalid request" do
      assert {:error, response} = Freshcom.register_user(%Request{})
    end

    # test "with valid command" do
    #   cmd = %RegisterUser{
    #     username: Faker.String.base64(8),
    #     password: Faker.String.base64(12),
    #     email: Faker.Internet.email(),
    #     is_term_accepted: true,
    #     name: Faker.Name.name()
    #   }
    #   :ok = Router.dispatch(cmd)

    #   assert_receive_event(UserRegistered, fn(event) ->
    #     assert event.username == String.downcase(cmd.username)
    #     assert event.default_account_id
    #     assert event.is_term_accepted == cmd.is_term_accepted
    #     assert event.name == cmd.name
    #     assert event.email == cmd.email
    #   end)

    #   assert_receive_event(EmailVerificationTokenGenerated, fn(event) ->
    #     assert event.token
    #     assert event.expires_at
    #   end)

    #   assert_receive_event(AccountCreated,
    #     fn(event) -> event.mode == "live" end,
    #     fn(event) ->
    #       assert event.name == "Unamed Account"
    #       assert event.default_locale == "en"
    #     end
    #   )

    #   assert_receive_event(AccountCreated,
    #     fn(event) -> event.mode == "test" end,
    #     fn(event) ->
    #       assert event.name == "Unamed Account"
    #       assert event.default_locale == "en"
    #     end
    #   )
    # end
  end
end