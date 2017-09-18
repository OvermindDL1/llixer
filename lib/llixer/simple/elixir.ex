defmodule Llixer.Simple.Elixir do

  import Llixer.Simple.Evaluator, only: [eval_sexpr: 2, binding_: 1, cmd_: 1, cmd_: 2]

  alias Llixer.Simple.Env

  def add_elixir_calls(env) do
    env
    |> Env.push(cmd_("Elixir.def", 3), {:macro, __MODULE__, :elixir_def, [], %{}})
  end

  def elixir_def(name, head, body) do
    []
  end
end
