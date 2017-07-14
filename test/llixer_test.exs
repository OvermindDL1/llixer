defmodule LlixerTest do
  use ExUnit.Case
  doctest Llixer

  import Llixer
  alias Llixer.Env

  test "Parsing" do
    assert %{rest: "", result: {:integer, _, 1}} = parse_expression "1"
    assert %{rest: "", result: {:name, _, "test"}} = parse_expression "test"
    assert %{rest: "", result: {:name, _, "test"}} = parse_expression " test "
    assert %{rest: "fail", result: {:name, _, "test"}} = parse_expression "test fail"
    assert %{rest: "", result: {:name, _, "test pass"}} = parse_expression "test\\ pass"
    assert %{rest: "", result: {:list, _, [{:integer, _, 1}]}} = parse_expression "(1)"
    assert %{rest: "", result: {:list, _, [{:integer, _, 1}, {:integer, _, 2}]}} = parse_expression "(1 2)"
    assert %{rest: "", result: {:list, _, [{:name, _, "+"}, {:integer, _, 1}, {:integer, _, 2}]}} = parse_expression "(+ 1 2)"
    assert %{rest: "", result: {:name, _, ":add"}} = parse_expression ":add"
    assert %{rest: "", result: {:name, _, ":+"}} = parse_expression ":+"
    assert %{rest: "", result: {:list, _, [{:name, _, ":+"}, {:integer, _, 1}, {:integer, _, 2}]}} = parse_expression "(:+ 1 2)"
    assert %{rest: "", result: {:name, _, "add"}} = parse_expression "add"
    assert %{rest: "", result: {:name, _, "A string"}} = parse_expression "A\\ string"
    assert 1 + 1 = 2
  end


  def test_add(args) do
    Enum.reduce(args, 0, &Kernel.+/2)
  end

  test "Calls - Calling" do
    env =
      Env.new(mapper: Llixer.Evaluator)
      |> Env.add_call("+", {Kernel, :+, 2, []})
      |> Env.add_call("add", {LlixerTest, :test_add, -1, []})

      assert {_env, 3} = eval_expression "(+ 1 2)", env: env
      assert {_env, 15} = eval_expression "(add 1 2 3 4 5)", env: env
  end


  test "Read-Macro - Quote" do
    env =
      Env.new(mapper: Llixer.Evaluator)
      |> Env.add_value("v", 42)

    assert {_env, 1}            = eval_expression "(quote 1)", env: env
    assert {_env, ["+", 1, 2]}  = eval_expression "(quote (+ 1 2))", env: env
    assert {_env, ["+", 42, 2]} = eval_expression "(quote (+ (unquote v) 2))", env: env

    assert {_env, 1}            = eval_expression "`1", env: env
    assert {_env, [1]}          = eval_expression "`(1)", env: env
    assert {_env, [1, 2]}       = eval_expression "`(1 2)", env: env
    assert {_env, ["+", 1, 2]}  = eval_expression "`(+ 1 2)", env: env
    assert {_env, 42}           = eval_expression "`,v", env: env
    assert {_env, 42}           = eval_expression "`(unquote v)", env: env
    assert {_env, 42}           = eval_expression "(quote (unquote v))", env: env
    assert {_env, ["+", 42, 2]} = eval_expression "`(+ ,v 2)", env: env
    assert {_env, ["+", 42, 2]} = eval_expression "`(+ (unquote v) 2)", env: env
  end


  test "Function - Anonymous" do
    env =
      Env.new(mapper: Llixer.Evaluator)

    assert {_env, fun} = eval_expression "(fn (-> (i) i) (-> (x) x))", env: env
    assert 42 = fun.(42)
  end
end
