defmodule Logic.Gate do
  alias __MODULE__, as: G
  use GenServer

  defstruct inputs: [], output_listeners: %{},
            name: nil, outputs_fn: nil

  def start_link(name, inputs, outputs_fn) do
    GenServer.start_link(G, {name, inputs, outputs_fn})
  end

  def init({name, inputs, outputs_fn}) do
    outputs = outputs_fn.(inputs)
    listeners = 1..length(outputs)
                |> Enum.reduce(%{}, &(Map.put(&2, &1 - 1, [])))
    {:ok, %G{name: name, inputs: inputs, outputs_fn: outputs_fn,
             output_listeners: listeners}}
  end

  def input(gate_pid, position, value), do: input({gate_pid, position}, value)
  def input({gate_pid, position}, value) do
    GenServer.cast(gate_pid, {:input, position, value})
  end

  def outputs(gate_pid) do
    GenServer.call(gate_pid, :outputs)
  end

  def connect(gate_pid, output_position, other_gate_pid, other_input_position) do
    GenServer.cast(gate_pid, {:connect, output_position, other_gate_pid, other_input_position})
  end

  def handle_call(:outputs, _from, gate = %G{}) do
    {:reply, gate.outputs_fn.(gate.inputs), gate}
  end

  def handle_cast({:input, position, value},
                   gate = %G{inputs: ins,
                             outputs_fn: outputs_fn,
                             output_listeners: listeners}) do
    if value != Enum.at(ins, position) do
      new_ins = List.replace_at(ins, position, value)
      outs = outputs_fn.(ins)
      new_outs = outputs_fn.(new_ins)
      if new_outs != outs do
        outs
        |> Enum.zip(new_outs)
        |> Enum.with_index()
        |> Enum.each(fn {{a, a}, _} -> nil
                        {{a, b}, i} -> Map.get(listeners, i)
                                       |> Enum.each(&(input(&1, b)))
                     end)
      end
      gate = %{gate | inputs: new_ins}
    end
    {:noreply, gate}
  end

  def handle_cast({:connect, output_position,
                   other_gate, other_input},
                   gate = %G{}) do
    other = {other_gate, other_input}
    input(other, gate.outputs_fn.(gate.inputs) |> Enum.at(output_position))
    listeners = gate.output_listeners
                |> Map.update(output_position, [other], &[other|&1])
    {:noreply, %{gate | output_listeners: listeners}}
  end
end
