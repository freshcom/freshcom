defmodule FCIdentity.UniqueValidator do

  use Vex.Validator

  def validate(value, by: by) do
    by.(value)
  end
end