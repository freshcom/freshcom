defmodule FCBase.RouterCase do
  use ExUnit.CaseTemplate
  import UUID
  import Commanded.Assertions.EventAssertions
  import Mox

  using do
    quote do
      import UUID
      import Commanded.Assertions.EventAssertions
      import Mox
      import FCBase.{RouterCase, Fixture}
    end
  end

  setup :set_mox_from_context
  setup :verify_on_exit!

  setup do
    {:ok, _} = Application.ensure_all_started(:commanded)
    {:ok, _} = Application.ensure_all_started(:eventstore)

    on_exit(fn ->
      :ok = Application.stop(:commanded)
      :ok = Application.stop(:eventstore)

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

    :ok = Commanded.EventStore.append_to_stream(stream_uuid, expected_version, event_data)
  end

  def to_streams(type, events) do
    id_key = String.to_existing_atom("#{type}_id")
    stream_prefix = "#{type}-"

    to_streams(id_key, stream_prefix, events)
  end

  def to_streams(id_key, stream_prefix, events) do
    groups = Enum.group_by(events, &Map.get(&1, id_key))

    Enum.each(groups, fn {id, events} ->
      append_to_stream("#{stream_prefix}" <> "#{id}", events)
    end)
  end

  def assert_event(event, fun) do
    assert_receive_event(event, fun, &(&1))
  end

  def assert_event(event) do
    assert_receive_event(event, &(&1), &(&1))
  end
end