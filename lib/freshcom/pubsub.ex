defmodule Freshcom.PubSub do
  def child_spec do
    config = Application.get_env(:freshcom, :pubsub)
    {adapter, config} = Keyword.pop(config, :adapter)
    name = config[:name] || __MODULE__

    [
      %{
        id: adapter,
        start: {adapter, :start_link, [name, config]},
        type: :supervisor
      }
    ]
  end
end
