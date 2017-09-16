defmodule Llixer.Simple.EvaluatorTest do
  use ExUnit.Case
  doctest Llixer.Simple.Evaluator

  alias Llixer.Simple.Env
  alias Llixer.Simple.Evaluator
  alias Llixer.Simple.SpecialForms

  test "Bindings" do
    env =
      Env.new()
      |> Env.push({:binding, "meaning"}, 42)

    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, "meaning")
  end
end
