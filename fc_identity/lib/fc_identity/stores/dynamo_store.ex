defmodule FCIdentity.DynamoStore do
  @behaviour FCIdentity.SimpleStore

  alias ExAws.Dynamo

  @dynamo_table System.get_env("AWS_DYNAMO_TABLE")
  @primary_key_name :__key

  def get(primary_key, _ \\ []) do
    raw_response =
      @dynamo_table
      |> Dynamo.get_item(%{@primary_key_name => primary_key})
      |> ExAws.request!()

    case parse_response(raw_response["Item"]) do
      nil -> nil
      m -> Map.drop(m, [@primary_key_name])
    end
  end

  defp parse_response(nil), do: nil

  defp parse_response(item) do
    Enum.reduce(item, %{}, fn({k, value_wrap}, acc) ->
      v =
        value_wrap
        |> Map.values()
        |> Enum.at(0)

      Map.put(acc, String.to_existing_atom(k), v)
    end)
  end

  def put(key, record, opts \\ [])

  def put(key, record, allow_overwrite: false) do
    dynamo_opts = [
      condition_expression: "attribute_not_exists(#key)",
      expression_attribute_names: %{"#key" => Atom.to_string(@primary_key_name)}
    ]
    record = Map.put(record, @primary_key_name, key)

    @dynamo_table
    |> Dynamo.put_item(record, dynamo_opts)
    |> ExAws.request()
    |> normalize_error()
  end

  def put(key, record, _) do
    record = Map.put(record, @primary_key_name, key)

    @dynamo_table
    |> Dynamo.put_item(record)
    |> ExAws.request!()

    {:ok, record}
  end

  defp normalize_error({:error, {"ConditionalCheckFailedException", _}}), do: {:error, :key_already_exist}
  defp normalize_error(other), do: other
end