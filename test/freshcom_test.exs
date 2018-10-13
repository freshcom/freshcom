defmodule FreshcomTest do
  use ExUnit.Case
  doctest Freshcom

  test "greets the world" do
    assert Freshcom.hello() == :world
  end
end
