defmodule Logic.Gates do
  @moduledoc """
  ## Examples

  XOR gate using inputs `in1` and `in2` with output from `a`

  ```elixir
      iex> alias Logic.Gate, as: G
      iex> alias Logic.Gates, as: Gs
      iex> in1 = Gs.Buffer.gate
      iex> in2 = Gs.Buffer.gate
      iex> o = Gs.Or.gate
      iex> na = Gs.And.gate
      iex> nn = Gs.Not.gate
      iex> G.connect na, :out, nn, :in
      iex> G.connect in1, :out, o, :a
      iex> G.connect in1, :out, na, :a
      iex> G.connect in2, :out, na, :b
      iex> G.connect in2, :out, o, :b
      iex> a = Gs.And.gate
      iex> G.connect o, :out, a, :a
      iex> G.connect nn, :out, a, :b
      iex> {G.inputs(in1) |> Map.merge(G.inputs(in2), fn _, v1, v2 -> {v1, v2} end), G.outputs(a)}
      {%{in: {false, false}}, %{out: false}}
      iex> G.input in1, :in, true
      iex> {G.inputs(in1) |> Map.merge(G.inputs(in2), fn _, v1, v2 -> {v1, v2} end), G.outputs(a)}
      {%{in: {true, false}}, %{out: true}}
      iex> G.input in2, :in, true
      iex> {G.inputs(in1) |> Map.merge(G.inputs(in2), fn _, v1, v2 -> {v1, v2} end), G.outputs(a)}
      {%{in: {true, true}}, %{out: false}}
      iex> G.input in1, :in, false
      iex> {G.inputs(in1) |> Map.merge(G.inputs(in2), fn _, v1, v2 -> {v1, v2} end), G.outputs(a)}
      {%{in: {false, true}}, %{out: true}}
  ```

  """

  alias __MODULE__, as: Gs
  alias Logic.Gate, as: G

  def gate(inputs, fun) do
    {:ok, pid} = G.start_link(inputs, fun)
    pid
  end

  defmodule Buffer do
    def gate() do
      Gs.gate([:in], fn %{in: input} -> %{out: input} end)
    end
  end

  defmodule Not do
    def gate() do
      Gs.gate([:in], fn %{in: input} -> %{out: Logic.not?(input)} end)
    end
  end

  defmodule And do
    def gate() do
      Gs.gate([:a, :b], fn %{a: a, b: b} ->
                                  %{out: Logic.and?(a, b)}
                                end)
    end
  end

  defmodule Or do
    def gate() do
      Gs.gate([:a, :b], fn %{a: a, b: b} ->
                          %{out: Logic.or?(a, b)}
                        end)
    end
  end

  def watch(gate, fun) do
    inputs = G.outputs(gate) |> Map.keys
    {:ok, watcher} = G.start_link(inputs, fn ins ->
                                            fun.(ins)
                                            ins
                                          end
                                 )
    inputs |> Enum.each(&G.connect(gate, &1, watcher, &1))
    watcher
  end
end
