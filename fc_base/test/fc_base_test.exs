defmodule FCBaseTest do
  use ExUnit.Case
  doctest FCBase

  test "greets the world" do
    assert FCBase.hello() == :world
  end
end
