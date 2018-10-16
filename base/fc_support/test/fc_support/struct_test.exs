defmodule FCSupport.StructTest do
  use ExUnit.Case
  import FCSupport.Struct

  defmodule TestStruct do
    defstruct [:id, :name]
  end

  test "merge/3" do
    assert merge(%TestStruct{}, %{"id" => 1}).id == 1
    assert merge(%TestStruct{}, %{"id" => 1}, except: [:id]).id == nil
    assert merge(%TestStruct{}, %{id: 1}).id == 1
    assert merge(%TestStruct{}, %{id: 1}, except: [:id]).id == nil
    assert merge(%TestStruct{}, %TestStruct{id: 1}).id == 1
    assert merge(%TestStruct{}, %TestStruct{id: 1}, except: [:id]).id == nil
    assert merge(%TestStruct{}, %TestStruct{id: 1}, only: [:name]).id == nil
  end
end
