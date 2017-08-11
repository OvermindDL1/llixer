defmodule LlixerTest do
  use ExUnit.Case
  doctest Llixer

  import Llixer
  # alias Llixer.Env

  test "Parsing" do
    assert %{rest: "", result: {:integer, _, 1}} = parse_expression "1"
    assert %{rest: "", result: {:float, _, 6.28}} = parse_expression "6.28"
    assert %{rest: "", result: {:name, _, "test"}} = parse_expression "test"
    assert %{rest: "", result: {:name, _, "test"}} = parse_expression " test "
    assert %{rest: "fail", result: {:name, _, "test"}} = parse_expression "test fail"
    assert %{rest: "", result: {:name, _, "test pass"}} = parse_expression "test\\ pass"
    assert %{rest: "", result: {:cmd, _, [{:integer, _, 1}]}} = parse_expression "(1)"
    assert %{rest: "", result: {:cmd, _, [{:integer, _, 1}, {:integer, _, 2}]}} = parse_expression "(1 2)"
    assert %{rest: "", result: {:cmd, _, [{:name, _, "+"}, {:integer, _, 1}, {:integer, _, 2}]}} = parse_expression "(+ 1 2)"
    assert %{rest: "", result: {:name, _, ":add"}} = parse_expression ":add"
    assert %{rest: "", result: {:name, _, ":+"}} = parse_expression ":+"
    assert %{rest: "", result: {:cmd, _, [{:name, _, ":+"}, {:integer, _, 1}, {:integer, _, 2}]}} = parse_expression "(:+ 1 2)"
    assert %{rest: "", result: {:name, _, "add"}} = parse_expression "add"
    assert %{rest: "", result: {:name, _, "A string"}} = parse_expression "A\\ string"
    assert %{rest: "", result: {:cmd, _, [{:name, _, "fn"}, {:cmd, _, [{:cmd, _, [{:name, _, "id"}]}, {:name, _, "id"}]}]}} = parse_expression "(fn ((id) id))"
  end

  test "Parsing - Read Macro's" do
    assert %{rest: "", result: {:cmd, _, [{:name, _, "quote"}, {:name, _, "x"}]}} = parse_expression "`x"
    assert %{rest: "", result: {:cmd, _, [{:name, _, "unquote"}, {:name, _, "x"}]}} = parse_expression ",x"
    assert %{rest: "", result: {:cmd, _, [{:name, _, "unquote-splicing"}, {:name, _, "x"}]}} = parse_expression ",@x"
  end


  def testcall(), do: 42
  def testcall(a), do: 42 + a
  test "Sigil" do
    test = 42

    # Direct values
    assert 1 = ~L{1}u
    assert 6.28 = ~L{6.28}u

    # Atoms
    assert :test         = ~L{atom test}
    assert :"split test" = ~L{atom split\ test}

    # Strings
    assert "test"       = ~L{string test}
    assert "split test" = ~L{string split\ test}

    # Lists
    assert []     = ~L{list}
    assert [1]    = ~L{list 1}
    assert [1, 2] = ~L{list 1 2}

    # Tuples
    assert {}     = ~L{tuple}
    assert {1}    = ~L{tuple 1}
    assert {1, 2} = ~L{tuple 1 2}

    # Maps
    assert %{}               = ~L{map}
    assert %{1 => 2}         = ~L{map (1 2)}
    assert %{1 => 2, 3 => 4} = ~L{map (1 2) (3 4)}

    # Mixed map
    assert %{{1, 2} => [3, 4]} = ~L{map ((tuple 1 2) (list 3 4))}

    # Local call
    assert 42 = ~L{testcall}
    assert 43 = ~L{testcall 1}
    assert 3 = ~L{+ 1 2}

    # Remote call
    assert "42" = ~L{Elixir.Kernel.inspect 42}

    # Anonymous function 0-arg
    assert 42 = ~L{fn (() 42)}.()
    assert 42 = ~L{fn (() () 42)}.()

    # Anonymous function 1-arg
    assert 42 = ~L{fn ((x) x)}.(42)
    assert 42 = ~L{fn ((x) (* x 2))}.(21)

    # Anonymous function 1-arg pattern matching
    assert 42 = ~L{fn ((0) 42) ((x) x)}.(0)

    # Anonymous function 1-arg guarded
    assert 42 = ~L{fn ((x) () x)}.(42)
    assert 42 = ~L{fn ((x) ((> x 0)) x)}.(42)
    assert 42 = ~L{fn ((x) ((> x 0)) x) ((x) ((< x 0)) (- x))}.(-42)

    # Quote
    assert {:name, _, "x"} = ~L{quote x}
    assert {:cmd, _, [{:name, _, "blah"}, {:integer, _, 1}]} = ~L{quote (blah 1)}
    assert 42 = ~L{quote (unquote test)}
    assert {:cmd, _, [{:name, _,"list"}, {:integer, _, 1}, {:name, _, "test"}, 42]} = ~L{quote (list 1 (unquote-splicing (list (quote test) test)))}

    # Read macro's
    assert {:name, _, "x"} = ~L{`x}u
    assert {:cmd, _, [{:name, _, "blah"}, {:integer, _, 1}]} = ~L{`(blah 1)}u
    assert 42 = ~L{`,test}u
    assert {:cmd, _, [{:name, _,"list"}, {:integer, _, 1}, {:name, _, "test"}, 42]} = ~L{`(list 1 ,@(list `test test))}u
  end

  ~L{Elixir.Kernel.defmodule (atom TestGenModule0) (list (do))}
  ~L{Elixir.Kernel.defmodule (atom TestGenModule1) (list (do
    (def get (list (do 42)))
    (def (id x) (list (do x)))
    (def (idq _x) (list (do (quote _x))))
    ))}
  test "Generated module tests" do
    assert :TestGenModule0 = :TestGenModule0.module_info()[:module]
    assert :TestGenModule1 = :TestGenModule1.module_info()[:module]
    assert 42 = :TestGenModule1.get()
    assert 42 = :TestGenModule1.id(42)
    assert {:name, _, "_x"} = :TestGenModule1.idq(42)
  end


  # def test_add(args) do
  #   Enum.reduce(args, 0, &Kernel.+/2)
  # end
  #
  # test "Calls - Calling" do
  #   env =
  #     Env.new(mapper: Llixer.Evaluator)
  #     |> Env.add_call("+", {Kernel, :+, 2, []})
  #     |> Env.add_call("add", {LlixerTest, :test_add, -1, []})
  #
  #     assert {_env, 3} = eval_expression "(+ 1 2)", env: env
  #     assert {_env, 15} = eval_expression "(add 1 2 3 4 5)", env: env
  # end
  #
  #
  # test "Read-Macro - Quote" do
  #   env =
  #     Env.new(mapper: Llixer.Evaluator)
  #     |> Env.add_value("v", 42)
  #
  #   assert {_env, 1}            = eval_expression "(quote 1)", env: env
  #   assert {_env, ["+", 1, 2]}  = eval_expression "(quote (+ 1 2))", env: env
  #   assert {_env, ["+", 42, 2]} = eval_expression "(quote (+ (unquote v) 2))", env: env
  #
  #   assert {_env, 1}            = eval_expression "`1", env: env
  #   assert {_env, [1]}          = eval_expression "`(1)", env: env
  #   assert {_env, [1, 2]}       = eval_expression "`(1 2)", env: env
  #   assert {_env, ["+", 1, 2]}  = eval_expression "`(+ 1 2)", env: env
  #   assert {_env, 42}           = eval_expression "`,v", env: env
  #   assert {_env, 42}           = eval_expression "`(unquote v)", env: env
  #   assert {_env, 42}           = eval_expression "(quote (unquote v))", env: env
  #   assert {_env, ["+", 42, 2]} = eval_expression "`(+ ,v 2)", env: env
  #   assert {_env, ["+", 42, 2]} = eval_expression "`(+ (unquote v) 2)", env: env
  # end
  #
  #
  # test "Function - Anonymous" do
  #   env =
  #     Env.new(mapper: Llixer.Evaluator)
  #
  #   assert {_env, fun} = eval_expression "(fn (-> (i) i) (-> (x) x))", env: env
  #   assert 42 = fun.(42)
  # end
end
