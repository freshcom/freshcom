defmodule FCIdentity.RouterCase do
  use ExUnit.CaseTemplate
  import UUID

  using do
    quote do
      import UUID
      import Commanded.Assertions.EventAssertions
      import FCIdentity.RouterCase
    end
  end

  setup do
    {:ok, _} = Application.ensure_all_started(:fc_identity)

    on_exit(fn ->
      :ok = Application.stop(:fc_identity)
      :ok = Application.stop(:commanded)
      :ok = Application.stop(:eventstore)

      FCIdentity.Storage.reset!()
    end)

    :ok
  end

  def append_to_stream(stream_uuid, events, expected_version \\ 0) do
    event_data =
      Enum.map(events, fn(event) ->
        %Commanded.EventStore.EventData{
          causation_id: uuid4(),
          correlation_id: uuid4(),
          event_type: Commanded.EventStore.TypeProvider.to_string(event),
          data: event,
          metadata: %{},
        }
      end)

    {:ok, _} = Commanded.EventStore.append_to_stream(stream_uuid, expected_version, event_data)
  end
end