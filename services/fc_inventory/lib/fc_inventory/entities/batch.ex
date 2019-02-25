defmodule FCInventory.Batch do
  use TypedStruct

  import UUID
  import FCSupport.Normalization

  alias Decimal, as: D

  typedstruct do
    field :storage_id, String.t()

    field :status, String.t(), default: "active"
    field :quantity_on_hand, Decimal.t(), default: D.new(0)
    field :quantity_reserved, Decimal.t(), default: D.new(0)
    field :expires_at, DateTime.t()
    field :transactions_inprogress, map(), default: %{}

    field :number, String.t()
    field :label, String.t()

    field :caption, String.t()
    field :description, String.t()
    field :custom_data, map()
    field :translations, map(), default: %{}
  end

  def translatable_fields do
    [
      :caption,
      :description,
      :custom_data
    ]
  end

  def deserialize(map) do
    %{struct(%__MODULE__{}, atomize_keys(map)) | quantity_on_hand: D.new(map["quantity_on_hand"])}
  end

  def is_available(%{status: "active"} = batch) do
    cond do
      is_nil(batch.expires_at) || Timex.before?(Timex.now(), batch.expires_at) ->
        D.cmp(batch.quantity_on_hand, batch.quantity_reserved) == :gt

      true ->
        false
    end
  end

  def is_available(_), do: false

  def add_transaction(batch, %{status: "completed"}), do: batch

  def add_transaction(%{transactions_inprogress: transactions} = batch, txn) do
    transactions = Map.put(transactions, uuid4(), txn)
    batch =
      if txn.status == "reserved" do
        quantity_reserved = D.add(batch.quantity_reserved, txn.quantity)
        %{batch | quantity_reserved: quantity_reserved}
      else
        batch
      end

    %{batch | transactions_inprogress: transactions}
  end
end
