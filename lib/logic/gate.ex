defmodule Logic.Gate do
  alias __MODULE__, as: G
  use GenServer

  defstruct inputs: [], wires: %{}, outputs_fn: nil

  def start_link(inputs, outputs_fn) do
    GenServer.start_link(G, {inputs, outputs_fn})
  end

  def init({inputs, outputs_fn}) do
    inputs = inputs |> Map.new(fn x -> {x, false} end)
    outputs = inputs |> do_outputs(outputs_fn)
    wires = outputs
            |> Map.keys
            |> Map.new(fn o -> {o, []} end)
    {:ok, %G{inputs: inputs, outputs_fn: outputs_fn, wires: wires}}
  end

  def input(gate_pid, input, value), do: input({gate_pid, input}, value)
  def input({gate_pid, input}, value) do
    gate_pid |> Kernel.send({:input, input, value})
  end

  def inputs(gate), do: gate |> inputs_and_outputs |> elem(0)
  def outputs(gate), do: gate |> inputs_and_outputs |> elem(1)

  def inputs_and_outputs(gate_pid) do
    GenServer.call(gate_pid, :inputs_and_outputs)
  end

  def connect(gate_pid, output, other_gate_pid, other_input) do
    GenServer.cast(gate_pid, {:connect, output, other_gate_pid, other_input})
  end

  def handle_call(:inputs_and_outputs, _from, gate = %G{}) do
    {:reply, {gate.inputs, gate.inputs |> do_outputs(gate.outputs_fn)}, gate}
  end

  def handle_info({:input, input, value}, g = %G{}) do
    old_value = g.inputs |> Map.get(input, false)
    {:noreply, do_input(input, old_value, value, g)}
  end

  def handle_cast({:connect, output, other_gate, other_input}, g = %G{}) do
    {:noreply, do_connect(output, {other_gate, other_input}, g)}
  end

  defp do_connect(output, other = {_g, _in_pos}, g = %G{}) do
    out_value = g.inputs |> do_outputs(g.outputs_fn) |> Map.get(output, false)
    # send current value to new connection
    other |> input(out_value)
    %{g | wires: g.wires |> Map.update(output, [other], &[other|&1])}
  end

  defp do_input(input, old_value, new_value, gate)
  defp do_input(_, v, v, g), do: g
  defp do_input(input, _, value, g = %G{}) do
    old_outs = g.inputs |> do_outputs(g.outputs_fn)
    new_ins = g.inputs |> Map.put(input, value)
    new_outs = new_ins |> do_outputs(g.outputs_fn)
    g.wires |> send_outputs(old_outs, new_outs)
    %{g | inputs: new_ins}
  end

  defp send_outputs(_, a, a), do: nil
  defp send_outputs(wires, old, new) do
    old
    |> Map.merge(new, fn _, a, a -> nil
                         o, _, b ->
                        wires
                        |> Map.get(o)
                        |> Enum.each(&(input(&1, b)))
                 end)
  end

  defp do_outputs(ins, fun), do: fun.(ins)
end
