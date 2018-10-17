defmodule Freshcom.Context do
  alias Freshcom.Response

  def to_response({:ok, data}) do
    {:ok, %Response{data: data}}
  end

  def to_response({:error, {:validation_failed, errors}}) do
    {:error, %Response{errors: errors}}
  end

  def to_response(result) do
    raise "unexpected result returned: #{result}"
  end

  def normalize_wait_result({:error, {:timeout, _}}), do: {:error, {:timeout, :projection_wait}}
  def normalize_wait_result(other), do: other

  def find_event(%{events: events}, module) do
    Enum.find(events, &(&1.__struct__ == module))
  end
end