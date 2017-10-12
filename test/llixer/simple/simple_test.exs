defmodule Llixer.SimpleTest do
  use ExUnit.Case
  doctest Llixer.Simple

  alias Llixer.Simple
  alias Llixer.Simple.Env

  test "read" do
    assert {:ok, "", "test"} = Simple.read("test")
    assert {:ok, "", []} = Simple.read("()")
    assert {:ok, "", ["test"]} = Simple.read("(test)")
    assert {:ok, ")", "test"} = Simple.read("test)")
    assert {:ok, "", "test"} = Simple.read(" test ")
    assert {:ok, "", [
      "let",
      ["a", ["atom", "test"]],
      ["b", ["lambda", ["a"], "a"]],
      ["funcall", "b", "a"]
    ]} = Simple.read("
      (let
       (a :test)
       (b (lambda (a) a))
       (funcall b a)
      )
    ")
    assert %ExSpirit.Parser.ParseException{} = Simple.read("(left open")
    assert %ExSpirit.Parser.ParseException{} = Simple.read(")")
    assert {:ok, "", ")"} = Simple.read("\\)")
  end

  test "eval" do
    assert {%Env{}, 42} = Simple.eval(["integer", "42"])
    assert {%Env{}, :test} = Simple.eval([
      "let",
      ["a", ["atom", "test"]],
      ["b", ["lambda", ["a"], "a"]],
      ["funcall", "b", "a"]
    ])
  end

  test "read_eval" do
    import Llixer.Simple
    assert {%Env{}, :test} = read_eval("""
      (let
       (a :test)
       (b (lambda (a) a))
       (funcall b a)
      )
    """)
    assert 42 = ~L(integer 42)
    assert :test = ~L"""
      let
       (a :test)
       (b (lambda (a) a))
       (funcall b a)
    """
    assert ["test", "a", "thing"] = ~L"`(test a ,`thing)"u
    assert :test = ~L"""
      Elixir.def test(a) a
    """
  end
end
