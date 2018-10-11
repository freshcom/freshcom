defmodule FCIdentity.FinishUserRegistration do
  use TypedStruct
  use Vex.Struct

  typedstruct do
    field :user_id, String.t()
    field :is_term_accepted, boolean, default: false
  end

  validates :user_id, presence: true, uuid: true
  validates :is_term_accepted, acceptance: true
end
