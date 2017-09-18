defmodule Llixer.Simple.Stdlib.ReadMacrosTest do
  use ExUnit.Case
  doctest Llixer.Simple.Stdlib.ReadMacros

  alias Llixer.Simple.Env
  alias Llixer.Simple.Parser
  alias Llixer.Simple.SpecialForms
  alias Llixer.Simple.Stdlib.ReadMacros

  setup_all do
    env =
      Env.new()
      |> Env.push_scope(:special_forms, SpecialForms.scope())
      |> Env.push_scope(:read_macros)
      |> ReadMacros.add_read_macros()
      |> Env.push_scope(:testing)
    {:ok, %{env: env}}
  end

  test "string - doublequotes", %{env: env} do
    assert %{error: nil, rest: "", result: ["string", "test"]} = Parser.parse_expression(env, "\"test\"")
  end

  test "charlists - singlequotes", %{env: env} do
    assert %{error: nil, rest: "", result: ["charlist", "test"]} = Parser.parse_expression(env, "'test'")
  end

  test "atoms - colon", %{env: env} do
    assert %{error: nil, rest: "", result: ["atom", "test"]} = Parser.parse_expression(env, ":test")
    assert %{error: nil, rest: "", result: ["atom", ["string", "test"]]} = Parser.parse_expression(env, ":\"test\"")
    assert %{error: nil, rest: "", result: ["atom", ["charlist", "test"]]} = Parser.parse_expression(env, ":'test'")
  end

  test "lists - straightbrackets", %{env: env} do
    assert %{error: nil, rest: "", result: ["list", "test"]} = Parser.parse_expression(env, "[test]")
    assert %{error: nil, rest: "", result: ["list", "test"]} = Parser.parse_expression(env, "[test ]")
    assert %{error: nil, rest: "", result: ["list", ["test"]]} = Parser.parse_expression(env, "[(test)]")
    assert %{error: nil, rest: "", result: ["list", ["list", "test"]]} = Parser.parse_expression(env, "[[test]]")
    assert %{error: nil, rest: "", result: ["list", "test1", "test2"]} = Parser.parse_expression(env, "[test1 test2]")
  end

  test "tuples - curlybrackets", %{env: env} do
    assert %{error: nil, rest: "", result: ["tuple", "test"]} = Parser.parse_expression(env, "{test}")
    assert %{error: nil, rest: "", result: ["tuple", "test"]} = Parser.parse_expression(env, "{test }")
    assert %{error: nil, rest: "", result: ["tuple", ["test"]]} = Parser.parse_expression(env, "{(test)}")
    assert %{error: nil, rest: "", result: ["tuple", ["tuple", "test"]]} = Parser.parse_expression(env, "{{test}}")
    assert %{error: nil, rest: "", result: ["tuple", "test1", "test2"]} = Parser.parse_expression(env, "{test1 test2}")
  end

  test "embedded", %{env: env} do
    assert %{error: nil, rest: "", result: ["list",
        ["tuple", ["atom", "key"], ["string", "value"]],
        ["string", "string"], ["charlist", "charlist"],
        ["string", "string with })]"]
      ]} =
      Parser.parse_expression(env, ~s([{:key "value"} "string" 'charlist' "string with }\)]"]))
  end

end
