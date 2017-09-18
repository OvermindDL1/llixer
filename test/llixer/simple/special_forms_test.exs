defmodule Llixer.Simple.SpecialFormsTest do
  use ExUnit.Case
  doctest Llixer.Simple.Evaluator

  alias Llixer.Simple.Env
  alias Llixer.Simple.Evaluator
  alias Llixer.Simple.SpecialForms

  setup_all do
    env =
      Env.new()
      |> Env.push_scope(:special_forms, SpecialForms.scope())
      |> Env.push_scope(:testing)
    {:ok, %{env: env}}
  end

  test "bindings", %{env: env} do
    env = Env.push(env, {:binding, "test"}, 42)

    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, ["binding", "test"]) # Convert a symbol to an atom
  end

  test "atoms", %{env: env} do
    assert {%Env{}, :test} = Evaluator.eval_sexpr(env, ["atom", "test"]) # Convert a symbol to an atom
    assert {%Env{}, :test} = Evaluator.eval_sexpr(env, ["atom", ["atom", "test"]]) # Pass through an atom, or die
    assert {%Env{}, true} = Evaluator.eval_sexpr(env, ["atom?", ["atom", "test"]]) # Test if atom
    assert {%Env{}, :test} = Evaluator.eval_sexpr(env, ["atom", ["string", "test"]]) # String becomes atom
    assert {%Env{}, :test} = Evaluator.eval_sexpr(env, ["atom", ["charlist", "test"]]) # charlist becomes atom
  end

  test "strings", %{env: env} do
    assert {%Env{}, "test"} = Evaluator.eval_sexpr(env, ["string", "test"]) # Convert a symbol to a string
    assert {%Env{}, "test"} = Evaluator.eval_sexpr(env, ["string", ["string", "test"]]) # Pass through a string, or die
    assert {%Env{}, true} = Evaluator.eval_sexpr(env, ["string?", ["string", "test"]]) # Test if string
  end

  test "integers", %{env: env} do
    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, ["integer", "42"]) # Convert a symbol to an integer
    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, ["integer", ["integer", "42"]]) # Pass through an integer, or die
    assert {%Env{}, true} = Evaluator.eval_sexpr(env, ["integer?", ["integer", "42"]]) # Test if integer
  end

  test "floats", %{env: env} do
    assert {%Env{}, 6.28} = Evaluator.eval_sexpr(env, ["float", "6.28"]) # Convert a symbol to an float
    assert {%Env{}, 6.28} = Evaluator.eval_sexpr(env, ["float", ["float", "6.28"]]) # Pass through an float, or die
    assert {%Env{}, true} = Evaluator.eval_sexpr(env, ["float?", ["float", "6.28"]]) # Test if float
  end

  test "charlists", %{env: env} do
    assert {%Env{}, 'test'} = Evaluator.eval_sexpr(env, ["charlist", "test"]) # Convert a symbol to a charlist
    assert {%Env{}, 'test'} = Evaluator.eval_sexpr(env, ["charlist", ["charlist", "test"]]) # Pass through a charlist, or die
  end

  test "lists", %{env: env} do
    assert {%Env{}, ["test"]} = Evaluator.eval_sexpr(env, ["list", ["string", "test"]])
    assert {%Env{}, ["test1", "test2"]} = Evaluator.eval_sexpr(env, ["list", ["string", "test1"], ["string", "test2"]])
    assert {%Env{}, [["test1", "test2"]]} = Evaluator.eval_sexpr(env, ["list", ["list", ["string", "test1"], ["string", "test2"]]])
    assert {%Env{}, [["test1", "test2"], "test3"]} = Evaluator.eval_sexpr(env, ["list", ["list", ["string", "test1"], ["string", "test2"]], ["string", "test3"]])
  end

  test "tuples", %{env: env} do
    assert {%Env{}, {"test"}} = Evaluator.eval_sexpr(env, ["tuple", ["string", "test"]])
    assert {%Env{}, {"test1", "test2"}} = Evaluator.eval_sexpr(env, ["tuple", ["string", "test1"], ["string", "test2"]])
    assert {%Env{}, {{"test1", "test2"}}} = Evaluator.eval_sexpr(env, ["tuple", ["tuple", ["string", "test1"], ["string", "test2"]]])
    assert {%Env{}, {{"test1", "test2"}, ["test"]}} = Evaluator.eval_sexpr(env, ["tuple", ["tuple", ["string", "test1"], ["string", "test2"]], ["list", ["string", "test"]]])
  end

  test "quote", %{env: env} do
    assert {%Env{}, "test"}   = Evaluator.eval_sexpr(env, ["quote", "test"])
    assert {%Env{}, ["test"]} = Evaluator.eval_sexpr(env, ["quote", ["test"]])
    assert {%Env{}, ["quote", ["test"]]} = Evaluator.eval_sexpr(env, ["quote", ["quote", ["test"]]])
  end

  test "quasiquote", %{env: env} do
    env =
      env
      |> Env.push({:binding, "i"}, -1)
      |> Env.push({:binding, "s"}, "test")
    assert {%Env{}, ["1", "2"]} = Evaluator.eval_sexpr(env, ["quasiquote", ["1", "2"]])
    assert {%Env{}, "test"} = Evaluator.eval_sexpr(env, ["quasiquote", "test"])
    assert {%Env{}, ["test"]} = Evaluator.eval_sexpr(env, ["quasiquote", ["test"]])
    assert {%Env{}, ["integer", "1"]} = Evaluator.eval_sexpr(env, ["quasiquote", ["unquote", ["integer", "1"]]])
    assert {%Env{}, ["integer", "-1"]} = Evaluator.eval_sexpr(env, ["quasiquote", ["unquote", "i"]])
    assert {%Env{}, "test"} = Evaluator.eval_sexpr(env, ["quasiquote", ["unquote", "s"]])
    assert {%Env{}, [["integer", "1"], ["integer", "-1"]]}   = Evaluator.eval_sexpr(env, ["quasiquote", ["unquote", ["list", ["integer", "1"], "i"]]])
    assert {%Env{}, [["test", ["integer", "-1"]]]} = Evaluator.eval_sexpr(env, ["quasiquote", [["unquote", ["list", "s", "i"]]]])
    assert {%Env{}, ["test", ["integer", "-1"]]}   = Evaluator.eval_sexpr(env, ["quasiquote", [["unquote-splicing", ["list", "s", "i"]]]])
  end

  test "funcall", %{env: env} do
    env =
      env
      |> Env.push({:binding, "f0"}, fn -> 42 end)
      |> Env.push({:binding, "f1"}, fn i -> i * 2 end)
      |> Env.push({:binding, "f2"}, fn a, b -> a + b end)

    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, ["funcall", "f0"])
    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, ["funcall", "f1", ["integer", "21"]])
    assert {%Env{}, 3} = Evaluator.eval_sexpr(env, ["funcall", "f2", ["integer", "1"], ["integer", "2"]])
  end

  test "lambda", %{env: env} do
    assert {%Env{}, fun} = Evaluator.eval_sexpr(env, ["lambda", [], ["integer", "42"]])
    assert 42 = fun.()

    assert {%Env{}, fun} = Evaluator.eval_sexpr(env, ["lambda", ["a"], "a"])
    assert 42 = fun.(42)

    assert {%Env{}, fun} = Evaluator.eval_sexpr(env, ["lambda", ["a", "b"], "b"])
    assert 42 = fun.(21, 42)

    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, ["funcall", ["lambda", ["a", "b"], "b"], ["integer", "21"], ["integer", "42"]])
  end

  test "let", %{env: env} do
    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, ["let", ["a", ["integer", "42"]], "a"])
    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, [
      "let",
      ["a", ["integer", "42"]],
      ["b", ["lambda", ["a"], "a"]],
      ["funcall", "b", "a"]
    ])
  end

  # test "defun" do, %{env: env} do
  #   assert {%Env{} = env, true} = Evaluator.eval_sexpr(env, ["defun", "get", [], ["string", "Docs"], ["integer", "42"]])
  #   assert {%Env{}, :blah} = Evaluator.eval_sexpr(env, ["get"])
  # end

end
