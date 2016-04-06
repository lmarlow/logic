defmodule Logic do
  def buffer(in1)
  def buffer(true), do: true
  def buffer(false), do: false

  def not?(in1)
  def not?(true), do: false
  def not?(false), do: true

  def and?(in1, in2)
  def and?(true, true), do: true
  def and?(_, _), do: false

  def nand?(in1, in2), do: and?(in1, in2) |> not?

  def or?(in1, in2)
  def or?(false, false), do: false
  def or?(_, _), do: true

  def nor?(in1, in2), do: or?(in1, in2) |> not?

  def xor?(in1, in2), do: and?(or?(in1, in2), nand?(in1, in2))
end
