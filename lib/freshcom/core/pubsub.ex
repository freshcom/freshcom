defmodule Freshcom.PubSub do
  @moduledoc false

  def child_spec(_) do
    config = Application.get_env(:freshcom, :pubsub)
    {adapter, config} = Keyword.pop(config, :adapter)
    name = config[:name] || __MODULE__

    %{
      id: adapter,
      start: {adapter, :start_link, [name, config]}
    }
  end
end
