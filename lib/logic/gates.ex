defmodule Logic.Gates do
  alias __MODULE__, as: Gs
  alias Logic.Gate, as: G

  def gate(fun) do
    {:arity, count} = :erlang.fun_info(fun, :arity)
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
    def gate(), do: Gs.gate(&[Logic.and?(&1, &2)])
  end

  defmodule Or do
    def gate(), do: Gs.gate(&[Logic.or?(&1, &2)])
  end
end
