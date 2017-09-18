defmodule Llixer.Simple.SpecialFormsTest do
  use ExUnit.Case
  doctest Llixer.Simple.Evaluator

  alias Llixer.Simple.Env
  alias Llixer.Simple.Evaluator
  alias Llixer.Simple.SpecialForms

  test "bindings" do
    env =
      Env.new()
      |> Env.push_scope(:special_forms, SpecialForms.scope())
      |> Env.push_scope(:testing)
      |> Env.push({:binding, "test"}, 42)

    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, ["binding", "test"]) # Convert a symbol to an atom
  end

  test "atoms" do
    env =
      Env.new()
      |> Env.push_scope(:special_forms, SpecialForms.scope())
      |> Env.push_scope(:testing)

    assert {%Env{}, :test} = Evaluator.eval_sexpr(env, ["atom", "test"]) # Convert a symbol to an atom
    assert {%Env{}, :test} = Evaluator.eval_sexpr(env, ["atom", ["atom", "test"]]) # Pass through an atom, or die
    assert {%Env{}, true} = Evaluator.eval_sexpr(env, ["atom?", ["atom", "test"]]) # Test if atom
  end

  test "strings" do
    env =
      Env.new()
      |> Env.push_scope(:special_forms, SpecialForms.scope())
      |> Env.push_scope(:testing)

    assert {%Env{}, "test"} = Evaluator.eval_sexpr(env, ["string", "test"]) # Convert a symbol to a string
    assert {%Env{}, "test"} = Evaluator.eval_sexpr(env, ["string", ["string", "test"]]) # Pass through a string, or die
    assert {%Env{}, true} = Evaluator.eval_sexpr(env, ["string?", ["string", "test"]]) # Test if string
  end

  test "integers" do
    env =
      Env.new()
      |> Env.push_scope(:special_forms, SpecialForms.scope())
      |> Env.push_scope(:testing)

    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, ["integer", "42"]) # Convert a symbol to an integer
    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, ["integer", ["integer", "42"]]) # Pass through an integer, or die
    assert {%Env{}, true} = Evaluator.eval_sexpr(env, ["integer?", ["integer", "42"]]) # Test if integer
  end

  test "floats" do
    env =
      Env.new()
      |> Env.push_scope(:special_forms, SpecialForms.scope())
      |> Env.push_scope(:testing)

    assert {%Env{}, 6.28} = Evaluator.eval_sexpr(env, ["float", "6.28"]) # Convert a symbol to an float
    assert {%Env{}, 6.28} = Evaluator.eval_sexpr(env, ["float", ["float", "6.28"]]) # Pass through an float, or die
    assert {%Env{}, true} = Evaluator.eval_sexpr(env, ["float?", ["float", "6.28"]]) # Test if float
  end

  test "lambda" do
    env =
      Env.new()
      |> Env.push_scope(:special_forms, SpecialForms.scope())
      |> Env.push_scope(:testing)

    assert {%Env{}, fun} = Evaluator.eval_sexpr(env, ["lambda", [], ["integer", "42"]])
    assert 42 = fun.()

    assert {%Env{}, fun} = Evaluator.eval_sexpr(env, ["lambda", ["a"], "a"])
    assert 42 = fun.(42)
  end

  # test "defun" do
  #   env =
  #     Env.new()
  #     |> Env.push_scope(:special_forms, SpecialForms.scope())
  #     |> Env.push_scope(:testing)
  #
  #   assert {%Env{} = env, true} = Evaluator.eval_sexpr(env, ["defun", "get", [], ["string", "Docs"], ["integer", "42"]])
  #   assert {%Env{}, :blah} = Evaluator.eval_sexpr(env, ["get"])
  # end

end
