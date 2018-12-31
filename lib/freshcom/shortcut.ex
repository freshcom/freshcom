defmodule Freshcom.Shortcut do
  alias Freshcom.{Request, Identity}

  def get_urt(account_id, user_id) do
    req = %Request{
      account_id: account_id,
      identifier: %{"user_id" => user_id},
      _role_: "system"
    }

    {:ok, %{data: urt}} = Identity.get_api_key(req)

    urt
  end

  def get_prt(account_id) do
    req = %Request{
      account_id: account_id,
      identifier: %{"user_id" => nil},
      _role_: "system"
    }

    {:ok, %{data: prt}} = Identity.get_api_key(req)

    prt
  end
end