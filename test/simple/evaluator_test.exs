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

  test "Atoms" do
    env =
      Env.new()
      |> Env.push_scope(:special_forms, SpecialForms.scope())

      assert {%Env{}, :test} = Evaluator.eval_sexpr(env, ["atom", "test"]) # Convert a symbol to an atom
      assert {%Env{}, :test} = Evaluator.eval_sexpr(env, ["atom", ["atom", "test"]]) # Pass through an atom, or die
      assert {%Env{}, true} = Evaluator.eval_sexpr(env, ["atom?", ["atom", "test"]]) # Test if atom
  end
end
