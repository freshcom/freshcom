defmodule FCSupportTest do
  use ExUnit.Case
  doctest FCSupport

  test "greets the world" do
    assert FCSupport.hello() == :world
  end
end
