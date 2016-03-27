defmodule LogicTest do
  alias Logic, as: L

  use ExUnit.Case
  doctest Logic

  test "buffer" do
    assert L.buffer(true)
    refute L.buffer(false)
  end

  test "not?" do
    refute L.not?(true)
    assert L.not?(false)
  end

  test "and?" do
    assert L.and?(true, true)
    refute L.and?(true, false)
    refute L.and?(false, true)
    refute L.and?(false, false)
  end

  test "nand?" do
    refute L.nand?(true, true)
    assert L.nand?(true, false)
    assert L.nand?(false, true)
    assert L.nand?(false, false)
  end

  test "or?" do
    assert L.or?(true, true)
    assert L.or?(true, false)
    assert L.or?(false, true)
    refute L.or?(false, false)
  end

  test "nor?" do
    refute L.nor?(true, true)
    refute L.nor?(true, false)
    refute L.nor?(false, true)
    assert L.nor?(false, false)
  end

  test "xor?" do
    refute L.xor?(true, true)
    assert L.xor?(true, false)
    assert L.xor?(false, true)
    refute L.xor?(false, false)
  end
end
