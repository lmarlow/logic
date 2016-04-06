defmodule Logic.Gate do
  alias __MODULE__, as: G
  use GenServer

  defstruct inputs: [], wires: %{}, outputs_fn: nil

  def start_link(inputs, outputs_fn) do
    GenServer.start_link(G, {inputs, outputs_fn})
  end

  def init({inputs, outputs_fn}) do
    outputs = inputs |> do_outputs(outputs_fn)
    wires = 1..length(outputs)
            |> Enum.reduce(%{}, &(Map.put(&2, &1 - 1, [])))
    {:ok, %G{inputs: inputs, outputs_fn: outputs_fn, wires: wires}}
  end

  def input(gate_pid, position, value), do: input({gate_pid, position}, value)
  def input({gate_pid, position}, value) do
    gate_pid |> Kernel.send({:input, position, value})
  end

  def inputs(gate), do: gate |> inputs_and_outputs |> elem(0)
  def outputs(gate), do: gate |> inputs_and_outputs |> elem(1)

  def inputs_and_outputs(gate_pid) do
    GenServer.call(gate_pid, :inputs_and_outputs)
  end

  def connect(gate_pid, output_position, other_gate_pid, other_input_position) do
    GenServer.cast(gate_pid, {:connect, output_position, other_gate_pid, other_input_position})
  end

  def handle_call(:inputs_and_outputs, _from, gate = %G{}) do
    {:reply, {gate.inputs, gate.inputs |> do_outputs(gate.outputs_fn)}, gate}
  end

  def handle_info({:input, position, value}, g = %G{}) do
    {:noreply, do_input(position, Enum.at(g.inputs, position), value, g)}
  end

  def handle_cast({:connect, out_position, other_gate, other_input}, g = %G{}) do
    {:noreply, do_connect(out_position, {other_gate, other_input}, g)}
  end

  defp do_connect(out_pos, other = {_g, _in_pos}, g = %G{}) do
    out_value = g.inputs |> do_outputs(g.outputs_fn) |> Enum.at(out_pos)
    # send current value to new connection
    other |> input(out_value)
    %{g | wires: g.wires |> Map.update(out_pos, [other], &[other|&1])}
  end

  defp do_input(position, old_value, new_value, gate)
  defp do_input(_, v, v, g), do: g
  defp do_input(p, _, value, g = %G{}) do
    old_outs = g.inputs |> do_outputs(g.outputs_fn)
    new_ins = g.inputs |> List.replace_at(p, value)
    new_outs = new_ins |> do_outputs(g.outputs_fn)
    g.wires |> send_outputs(old_outs, new_outs)
    %{g | inputs: new_ins}
  end

  defp send_outputs(_, a, a), do: nil
  defp send_outputs(wires, old, new) do
    old
    |> Enum.zip(new)
    |> Enum.with_index()
    |> Enum.each(fn {{a, a}, _} -> nil
                    {{_, b}, i} -> wires
                                   |> Map.get(i)
                                   |> Enum.each(&(input(&1, b)))
                 end)
  end

  defp do_outputs(ins, fun), do: apply(fun, ins)
end
