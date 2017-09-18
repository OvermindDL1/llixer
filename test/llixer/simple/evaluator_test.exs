defmodule Llixer.Simple.EvaluatorTest do
  use ExUnit.Case
  doctest Llixer.Simple.Evaluator

  alias Llixer.Simple.Env
  alias Llixer.Simple.Evaluator

  test "Bindings" do
    env =
      Env.new()
      |> Env.push(Evaluator.binding_("meaning"), 42)

    assert {%Env{}, 42} = Evaluator.eval_sexpr(env, "meaning")
  end

  def test_special_form(env, [_cmd, sexpr]) do
    {env, sexpr}
  end
  test "Special Forms" do
    env =
      Env.new()
      |> Env.push(Evaluator.cmd_("test1"), {:special_form, __MODULE__, :test_special_form, [], %{}})
      |> Env.push(Evaluator.cmd_("test2"), {:special_form, &test_special_form/2, %{}})
      |> Env.push(Evaluator.cmd_("test3", 1), {:special_form, __MODULE__, :test_special_form, [], %{}})
      |> Env.push(Evaluator.cmd_("test4", 1), {:special_form, &test_special_form/2, %{}})

    assert {%Env{}, "blah"} = Evaluator.eval_sexpr(env, ["test1", "blah"])
    assert {%Env{}, "blah"} = Evaluator.eval_sexpr(env, ["test2", "blah"])
    assert {%Env{}, "blah"} = Evaluator.eval_sexpr(env, ["test3", "blah"])
    assert {%Env{}, "blah"} = Evaluator.eval_sexpr(env, ["test4", "blah"])
  end

  def test_macro1(_ignore) do
    []
  end
  test "Macro calls" do
    env =
      Env.new()
      |> Env.push(Evaluator.cmd_("test1"), {:macro, __MODULE__, :test_macro1, [], %{}}) # no arity passes all args as a single list
      |> Env.push(Evaluator.cmd_("test2"), {:macro, &test_macro1/1, %{}})
      |> Env.push(Evaluator.cmd_("test3", 1), {:macro, __MODULE__, :test_macro1, [], %{}}) # with arity expands args
      |> Env.push(Evaluator.cmd_("test4", 1), {:macro, &test_macro1/1, %{}})

    assert {%Env{}, []} = Evaluator.eval_sexpr(env, ["test1", "ignored"])
    assert {%Env{}, []} = Evaluator.eval_sexpr(env, ["test2", "ignored"])
    assert {%Env{}, []} = Evaluator.eval_sexpr(env, ["test3", "ignored"])
    assert {%Env{}, []} = Evaluator.eval_sexpr(env, ["test4", "ignored"])
  end


  def test_fun1(value) do
    value
  end
  test "Function calls" do
    env =
      Env.new()
      |> Env.push(Evaluator.cmd_("test1"), {:function, __MODULE__, :test_fun1, [], %{}}) # no arity passes all args as a single list
      |> Env.push(Evaluator.cmd_("test2"), {:function, &test_fun1/1, %{}})
      |> Env.push(Evaluator.cmd_("test3", 1), {:function, __MODULE__, :test_fun1, [], %{}}) # with arity expands args
      |> Env.push(Evaluator.cmd_("test4", 1), {:function, &test_fun1/1, %{}})

    assert {%Env{}, [[]]} = Evaluator.eval_sexpr(env, ["test1", []])
    assert {%Env{}, [[]]} = Evaluator.eval_sexpr(env, ["test2", []])
    assert {%Env{}, []} = Evaluator.eval_sexpr(env, ["test3", []])
    assert {%Env{}, []} = Evaluator.eval_sexpr(env, ["test4", []])
  end
end
