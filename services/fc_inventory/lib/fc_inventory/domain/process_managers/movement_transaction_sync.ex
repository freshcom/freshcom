# defmodule FCInventory.MovementTransactionSync do
#   @moduledoc false
#   use TypedStruct

#   use Commanded.ProcessManagers.ProcessManager,
#     name: "process-manager:53ac56ad-50f5-4e6c-807d-a638f57088fd",
#     router: FCInventory.Router

#   alias FCInventory.{
#     UpdateTransaction,
#     MarkMovement
#   }

#   alias FCInventory.{
#     MovementUpdated,
#     MovementMarked,
#     TransactionMarked,
#     TransactionPrepared,
#     TransactionPrepFailed,
#     TransactionDeleted,
#     TransactionCommitted
#   }

#   @derive Jason.Encoder
#   defstruct []

#   def interested?(%MovementPrepRequested{} = event), do: {:ok, event.movement_id}
#   def interested?(%MovementUpdated{} = event), do: {:start, event.movement_id}
#   def interested?(%TransactionMarked{} = event), do: {:start, event.movement_id}
#   def interested?(%TransactionPrepFailed{} = event), do: {:start, event.movement_id}
#   def interested?(%TransactionPrepared{} = event), do: {:start, event.movement_id}
#   def interested?(%TransactionDeleted{} = event), do: {:start, event.movement_id}
#   def interested?(%TransactionCommitted{} = event), do: {:start, event.movement_id}

#   def interested?(%MovementMarked{} = event), do: {:stop, event.movement_id}
#   def interested?(%TransactionUpdated = event), do: {:stop, event.movement_id}
#   def interested?(_), do: false

#   def handle(_, %MovementPrepRequested{} = event) do

#   end

#   def handle(_, %et{status: "action_required"} = event) when et in [TransactionMarked, TransactionPrepared] do
#     %MarkMovement{
#       requester_role: "system",
#       account_id: event.account_id,
#       movement_id: event.movement_id,
#       status: "action_required"
#     }
#   end

#   def handle(_, %et{status: "ready"} = event) when et in [TransactionMarked, TransactionPrepared] do
#     %MarkMovement{
#       requester_role: "system",
#       account_id: event.account_id,
#       movement_id: event.movement_id,
#       status: "action_required"
#     }
#   end

#   def handle(_, %TransactionPrepFailed{} = event) do
#     %MarkMovement{
#       requester_role: "system",
#       account_id: event.account_id,
#       movement_id: event.movement_id,
#       status: "action_required"
#     }
#   end
# end
