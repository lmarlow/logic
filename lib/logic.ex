defmodule Logic do
  def buffer(in1)
  def buffer(true), do: true
  def buffer(false), do: false
  def buffer([a]), do: buffer(a)

  def not?(in1)
  def not?(true), do: false
  def not?(false), do: true
  def not?([a]), do: not?(a)

  def and?(in1, in2)
  def and?(true, true), do: true
  def and?(_, _), do: false
  def and?([a, b]), do: and?(a, b)

  def nand?(in1, in2), do: and?(in1, in2) |> not?
  def nand?([a, b]), do: nand?(a, b)

  def or?(in1, in2)
  def or?(false, false), do: false
  def or?(_, _), do: true
  def or?([a, b]), do: or?(a, b)

  def nor?(in1, in2), do: or?(in1, in2) |> not?
  def nor?([a, b]), do: nor?(a, b)

  def xor?(in1, in2), do: and?(or?(in1, in2), nand?(in1, in2))
  def xor?([a, b]), do: xor?(a, b)
end
