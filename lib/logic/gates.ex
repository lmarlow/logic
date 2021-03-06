defmodule Logic.Gates do
  @moduledoc """
  ## Examples

  XOR gate using inputs `in1` and `in2` with output from `a`

      iex> alias Logic.Gate, as: G
      iex> alias Logic.Gates, as: Gs
      iex> in1 = Gs.Buffer.gate
      iex> in2 = Gs.Buffer.gate
      iex> o = Gs.Or.gate
      iex> na = Gs.And.gate
      iex> nn = Gs.Not.gate
      iex> G.connect na, 0, nn, 0
      iex> G.connect in1, 0, o, 0
      iex> G.connect in1, 0, na, 0
      iex> G.connect in2, 0, na, 1
      iex> G.connect in2, 0, o, 1
      iex> a = Gs.And.gate
      iex> G.connect o, 0, a, 0
      iex> G.connect nn, 0, a, 1
      iex> {List.flatten(G.inputs(in1), G.inputs(in2)), G.outputs(a)}
      {[false, false], [false]}
      iex> G.input in1, 0, true
      iex> {List.flatten(G.inputs(in1), G.inputs(in2)), G.outputs(a)}
      {[true, false], [true]}
      iex> G.input in2, 0, true
      iex> {List.flatten(G.inputs(in1), G.inputs(in2)), G.outputs(a)}
      {[true, true], [false]}
      iex> G.input in1, 0, false
      iex> {List.flatten(G.inputs(in1), G.inputs(in2)), G.outputs(a)}
      {[false, true], [true]}

  """

  alias __MODULE__, as: Gs
  alias Logic.Gate, as: G

  def gate(fun, count \\ 1) do
    {:ok, pid} = G.start_link(List.duplicate(false, count), fun)
    pid
  end

  defmodule Buffer do
    def gate(), do: Gs.gate(&[Logic.buffer(&1)])
  end

  defmodule Not do
    def gate(), do: Gs.gate(&[Logic.not?(&1)])
  end

  defmodule And do
    def gate(), do: Gs.gate(&[Logic.and?(&1)], 2)
  end

  defmodule Or do
    def gate(), do: Gs.gate(&[Logic.or?(&1)], 2)
  end

  def watch(gate, fun) do
    inputs = G.outputs(gate)
    {:ok, watcher} = G.start_link(inputs, fn ins ->
                                            fun.(ins)
                                            ins
                                          end
                                 )
    1..length(inputs)
    |> Enum.each(&G.connect(gate, &1 - 1, watcher, &1 - 1))
    watcher
  end
end
