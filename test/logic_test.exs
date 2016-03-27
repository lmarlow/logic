defmodule LogicTest do
  use ExUnit.Case
  doctest Logic

  test "buffer" do
    assert buffer(true)
    assert buffer(1)
    refute buffer(false)
    refute buffer(0)
  end
end
