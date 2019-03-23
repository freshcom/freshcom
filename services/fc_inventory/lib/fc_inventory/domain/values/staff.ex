defmodule FCInventory.Staff do
  alias FCInventory.{Manager, Associate, Worker}

  @type t :: Manager.t() | Associate.t() | Worker.t()

  @callback from(Staff.t()) :: Staff.t() | nil
end

defmodule FCInventory.System do
  use TypedStruct

  typedstruct do
    field :account_id, String.t(), enforce: true
    field :id, String.t(), default: "system"
  end
end

defmodule FCInventory.Manager do
  use TypedStruct

  typedstruct do
    field :account_id, String.t(), enforce: true
    field :id, String.t(), enforce: true
  end
end

defmodule FCInventory.Associate do
  use TypedStruct

  typedstruct do
    field :account_id, String.t(), enforce: true
    field :id, String.t(), enforce: true
  end
end

defmodule FCInventory.Worker do
  alias FCInventory.Staff

  @behaviour Staff

  use TypedStruct

  typedstruct do
    field :account_id, String.t(), enforce: true
    field :id, String.t(), enforce: true
  end

  @impl Staff
  def from(staff) do
    %__MODULE__{account_id: staff.account_id, id: staff.id}
  end
end