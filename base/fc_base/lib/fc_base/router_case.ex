defmodule FCBase.RouterCase do
  use ExUnit.CaseTemplate
  import UUID

  using do
    quote do
      import UUID
      import Commanded.Assertions.EventAssertions
      import FCBase.{RouterCase, Fixture}
    end
  end

  setup do
    {:ok, _} = Application.ensure_all_started(:commanded)

    on_exit(fn ->
      :ok = Application.stop(:commanded)

      FCBase.EventStore.reset!()
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

  def to_streams(type, events) do
    id_key = String.to_existing_atom("#{type}_id")
    groups = Enum.group_by(events, &Map.get(&1, id_key))

    Enum.each(groups, fn {id, events} ->
      append_to_stream("#{type}-" <> id, events)
    end)
  end
end