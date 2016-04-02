defmodule Logic.Gate do
  alias __MODULE__, as: G
  use GenServer

  defstruct inputs: [], output_listeners: %{}, outputs_fn: nil

  def start_link(inputs, outputs_fn) do
    GenServer.start_link(G, {inputs, outputs_fn})
  end

  def init({inputs, outputs_fn}) do
    outputs = do_outputs(outputs_fn, inputs)
    listeners = 1..length(outputs)
                |> Enum.reduce(%{}, &(Map.put(&2, &1 - 1, [])))
    {:ok, %G{inputs: inputs, outputs_fn: outputs_fn, output_listeners: listeners}}
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
    {:reply, {gate.inputs, do_outputs(gate.outputs_fn, gate.inputs)}, gate}
  end

  def handle_info({:input, _, _} = input, g), do: do_input(input, g)

  def handle_cast({:connect, output_position,
                   other_gate, other_input},
                   gate = %G{}) do
    other = {other_gate, other_input}
    input(other, do_outputs(gate.outputs_fn, gate.inputs)
                 |> Enum.at(output_position)
         )
    listeners = gate.output_listeners
                |> Map.update(output_position, [other], &[other|&1])
    {:noreply, %{gate | output_listeners: listeners}}
  end

  defp do_input({:input, position, value},
                gate = %G{inputs: ins,
                          outputs_fn: outputs_fn,
                          output_listeners: listeners}) do
    if value != Enum.at(ins, position) do
      new_ins = List.replace_at(ins, position, value)
      outs = do_outputs(outputs_fn, ins)
      new_outs = do_outputs(outputs_fn, new_ins)
      if new_outs != outs do
        outs
        |> Enum.zip(new_outs)
        |> Enum.with_index()
        |> Enum.each(fn {{a, a}, _} -> nil
                        {{_, b}, i} -> Map.get(listeners, i)
                                       |> Enum.each(&(input(&1, b)))
                     end)
      end
      gate = %{gate | inputs: new_ins}
    end
    {:noreply, gate}
  end

  defp do_outputs(fun, ins), do: apply(fun, ins)
end
