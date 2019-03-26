defmodule FCInventory.Batch do
  use TypedStruct

  import FCSupport.Normalization

  alias Decimal, as: D
  alias FCInventory.SerialNumberStore

  typedstruct do
    field :account_id, String.t()

    field :status, String.t(), default: "active"
    field :quantity_on_hand, Decimal.t(), default: D.new(0)
    field :quantity_reserved, Decimal.t(), default: D.new(0)
    field :quantity_incoming, Decimal.t(), default: D.new(0)
    field :txn_entries, map(), default: %{}
    field :added_at, DateTime.t()
  end

  def deserialize(map) do
    %{
      struct(%__MODULE__{}, atomize_keys(map))
      | quantity_on_hand: D.new(map["quantity_on_hand"]),
        added_at: from_utc_iso8601(map["added_at"])
    }
  end

  def remove_at(batch, sn) do
    case SerialNumberStore.get(batch.account_id, sn) do
      nil -> nil
      %{remove_at: remove_at} -> remove_at
    end
  end

  def expires_at(batch, sn) do
    case SerialNumberStore.get(batch.account_id, sn) do
      nil -> nil
      %{expires_at: expires_at} -> expires_at
    end
  end

  def is_available(%{status: "active"} = batch, sn) do
    remove_at = remove_at(batch, sn)

    cond do
      is_nil(remove_at) || Timex.before?(Timex.now(), remove_at) ->
        D.cmp(batch.quantity_on_hand, batch.quantity_reserved) == :gt

      true ->
        false
    end
  end

  def is_available(_), do: false

  def available(batches) do
    Enum.reduce(batches, %{}, fn {sn, batch}, acc ->
      if is_available(batch, sn) do
        Map.put(acc, sn, batch)
      else
        acc
      end
    end)
  end

  def quantity_available(batch) do
    D.sub(batch.quantity_on_hand, batch.quantity_reserved)
  end

  def sort(batches, strategy) when is_map(batches) do
    sort(Enum.into(batches, []), strategy)
  end

  def sort(batches, "fefo") do
    Enum.sort(batches, fn {sn1, batch1}, {sn2, batch2} ->
      expires_at1 = expires_at(batch1, sn1)
      expires_at2 = expires_at(batch2, sn2)

      cond do
        is_nil(expires_at1) && is_nil(expires_at2) ->
          true

        !is_nil(expires_at1) && !is_nil(expires_at2) ->
          Timex.compare(expires_at1, expires_at2) != 1

        is_nil(expires_at1) ->
          false

        is_nil(expires_at2) ->
          true
      end
    end)
  end

  def sort(batches, "fifo") do
    Enum.sort(batches, fn {_, batch1}, {_, batch2} ->
      Timex.compare(batch1.added_at, batch2.added_at) != 1
    end)
  end

  def sort(batches, "lifo") do
    Enum.sort(batches, fn {_, batch1}, {_, batch2} ->
      Timex.compare(batch1.added_at, batch2.added_at) == 1
    end)
  end

  def with_serial_number(batches, nil), do: batches

  def with_serial_number(batches, serial_number) do
    Enum.reduce(batches, %{}, fn {id, batch}, acc ->
      if batch.serial_number == serial_number do
        Map.put(acc, id, batch)
      else
        acc
      end
    end)
  end

  def entries(%__MODULE__{txn_entries: txn_entries}) do
    Enum.reduce(txn_entries, %{}, fn {txn_id, entries}, acc ->
      Map.merge(acc, entries)
    end)
  end

  def entries(batches) do
    Enum.reduce(batches, %{}, fn {sn, batch}, acc ->
      Map.merge(acc, entries(batch))
    end)
  end

  def entries(batches, transaction_id) do
    Enum.reduce(batches, %{}, fn {_, batch}, acc ->
      Map.merge(acc, (batch.txn_entries[transaction_id] || %{}))
    end)
  end

  def add_entry(batches, serial_number, entry) do
    batch =
      batches
      |> Map.put_new(serial_number, %__MODULE__{account_id: entry.account_id, added_at: Timex.now()})
      |> Map.get(serial_number)
      |> add_entry(entry)

    Map.put(batches, serial_number, batch)
  end

  def add_entry(batch, %{status: "planned"} = entry) do
    entries = batch.txn_entries[entry.transaction_id] || %{}
    entries = Map.put(entries, entry.id, entry)

    txn_entries = Map.put(batch.txn_entries, entry.transaction_id, entries)
    batch = Map.put(batch, :txn_entries, txn_entries)

    case D.cmp(entry.quantity, D.new(0)) do
      :lt ->
        inc_reserved(batch, D.minus(entry.quantity))

      :gt ->
        inc_incoming(batch, entry.quantity)
    end
  end

  def add_entry(batch, %{status: "committed"} = entry) do
    qoh = D.add(batch.quantity_on_hand, entry.quantity)
    %{batch | quantity_on_hand: qoh}
  end

  def get_entry(batches, serial_number, transaction_id, entry_id) do
    batches
    |> Map.get(serial_number, %{})
    |> Map.get(:txn_entries, %{})
    |> Map.get(transaction_id, %{})
    |> Map.get(entry_id)
  end

  def commit_entry(%__MODULE__{txn_entries: txn_entries} = batch, transaction_id, entry_id) do
    entries = txn_entries[transaction_id]
    entry = entries[entry_id]

    entries = Map.drop(entries, [entry_id])
    txn_entries = Map.put(txn_entries, transaction_id, entries)

    case D.cmp(entry.quantity, D.new(0)) do
      :lt ->
        %{
          batch
          | txn_entries: txn_entries,
            quantity_reserved: D.add(batch.quantity_reserved, entry.quantity),
            quantity_on_hand: D.add(batch.quantity_on_hand, entry.quantity)
        }

      :gt ->
        %{
          batch
          | txn_entries: txn_entries,
            quantity_incoming: D.sub(batch.quantity_incoming, entry.quantity),
            quantity_on_hand: D.add(batch.quantity_on_hand, entry.quantity)
        }
    end
  end

  def commit_entry(batches, serial_number, transaction_id, entry_id) do
    batch = commit_entry(batches[serial_number], transaction_id, entry_id)
    Map.put(batches, serial_number, batch)
  end

  def put_entry(%{txn_entries: txn_entries} = batch, entry_id, entry) do
    entries = txn_entries[entry.transaction_id]
    entries = Map.put(entries, entry_id, entry)
    txn_entries = Map.put(txn_entries, entry.transaction_id, entries)

    %{batch | txn_entries: txn_entries}
  end

  def put_entry(batches, entry_id, entry) do
    batch =
      batches
      |> Map.get(entry.serial_number)
      |> put_entry(entry_id, entry)

    Map.put(batches, entry.serial_number, batch)
  end

  def delete_entry(batches, serial_number, transaction_id, entry_id) do
    batch =
      batches
      |> Map.get(serial_number)
      |> delete_entry(transaction_id, entry_id)

    case batch do
      nil -> batches
      _ -> Map.put(batches, serial_number, batch)
    end
  end

  def delete_entry(%{txn_entries: txn_entries} = batch, transaction_id, entry_id) do
    entries = txn_entries[transaction_id]
    entry = entries[entry_id]

    entries = Map.drop(entries, [entry_id])
    txn_entries = Map.put(txn_entries, transaction_id, entries)

    batch = %{batch | txn_entries: txn_entries}

    case D.cmp(entry.quantity, D.new(0)) do
      :gt ->
        %{batch | quantity_incoming: D.sub(batch.quantity_incoming, entry.quantity)}

      :lt ->
        %{batch | quantity_reserved: D.sub(batch.quantity_reserved, entry.quantity)}
    end
  end

  def delete_entry(nil, _, _), do: nil

  def inc_reserved(batch, quantity) do
    %{batch | quantity_reserved: D.add(batch.quantity_reserved, quantity)}
  end

  def inc_incoming(batch, quantity) do
    %{batch | quantity_incoming: D.add(batch.quantity_incoming, quantity)}
  end

  # def reservations(%{reservations: all}, movement_id) do
  #   Enum.reduce(all, %{}, fn {id, rsv}, reservations ->
  #     if rsv.movement_id == movement_id do
  #       Map.put(reservations, id, rsv)
  #     else
  #       reservations
  #     end
  #   end)
  # end

  # def add_reservation(batch, %{status: "fulfilled"}), do: batch

  # def add_reservation(%{reservations: reservations} = batch, rsv) do
  #   reservations = Map.put(reservations, uuid4(), rsv)
  #   quantity_reserved = D.add(batch.quantity_reserved, rsv.quantity)

  #   %{
  #     batch
  #     | reservations: reservations,
  #       quantity_reserved: quantity_reserved
  #   }
  # end

  # def decrease_reservation(%{reservations: reservations} = batch, rsv_id, quantity) do
  #   rsv = BatchReservation.decrease(reservations[rsv_id], quantity)
  #   reservations = Map.put(reservations, rsv_id, rsv)
  #   quantity_reserved = D.sub(batch.quantity_reserved, quantity)

  #   %{
  #     batch
  #     | reservations: reservations,
  #       quantity_reserved: quantity_reserved
  #   }
  # end
end
