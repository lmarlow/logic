defmodule Logic.HDL do
  @moduledoc """
  ## Examples

  XOR gate using inputs `:a` and `:b` with output from `:out`

  ```elixir
      iex> alias Logic.Gate, as: G
      iex> {:ok, xor} = Logic.HDL.chip Xor,
      ...>                in: [:a, :b],
      ...>                out: [:out],
      ...>                parts: [ {Or,   [a: :a, b: :b], [out: :or_out]},
      ...>                         {Nand, [a: :a, b: :b], [out: :nand_out]},
      ...>                         {And,  [a: :or_out, b: :nand_out], [out: :out]}]
      iex> G.inputs_and_outputs(xor)
      {%{a: false, b: false}, %{out: false}}
      iex> G.input xor, :a, true
      iex> G.inputs_and_outputs(xor)
      {%{a: true, b: false}, %{out: true}}
      iex> G.input xor, :b, true
      iex> G.inputs_and_outputs(xor)
      {%{a: true, b: true}, %{out: false}}
      iex> G.input xor, :a, false
      iex> G.inputs_and_outputs(xor)
      {%{a: false, b: true}, %{out: true}}
  ```

  """

  def chip(_name, in: input_names, out: output_names, parts: parts) do
    in_pins  = input_names  |> Enum.map(&{Buffer, [in: false], [out: &1]})
    out_pins = output_names |> Enum.map(&{Buffer, [in: &1], [out: false]})
    out_gates = out_pins |> Enum.map(&make_gate/1)
    gates = in_pins ++ parts |> Enum.map(&make_gate/1)
    output_map = gates ++ out_gates |> Enum.reduce(%{}, &make_output_map/2)
    connect_wires(gates, output_map)
    Logic.Gate.start_link(input_names, make_outputs_fn(output_names, out_gates))
  end

  defp make_gate({gate_name, in_wires, out_wires}) do
    gate = Module.concat(Logic.Gates, gate_name).gate()
    {gate, gate_name, in_wires, out_wires}
  end

  defp make_output_map({gate, _, _, outs}, acc = %{}) do
    outs |> Enum.reduce(acc, fn {_, false}, acc2 -> acc2
                                {g_name, alt_name}, acc2 -> Map.put(acc2, alt_name, {gate, g_name})
                             end)
  end

  defp connect_wires(gates, output_map) do
    for {in_gate, _, ins, _} <- gates, {in_name, connect_to} <- ins, connect_to != false do
      {out_gate, out_name} = Map.fetch!(output_map, connect_to)
      Logic.Gate.connect(out_gate, out_name, in_gate, in_name)
    end
  end

  defp make_outputs_fn(output_names, out_gates) do
    out_gates = out_gates |> Enum.map(&(elem(&1, 0)))
    outs = output_names |> Enum.zip(out_gates)
    fn _ -> outs
            |> Enum.map(fn {name, gate} ->
                          {name, Map.get(Logic.Gate.outputs(gate), name, false)}
                        end)
            |> Enum.into(%{})
    end
  end
end
