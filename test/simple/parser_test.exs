defmodule Llixer.Simple.ParserTest do
  use ExUnit.Case
  doctest Llixer.Simple.Parser

  alias Llixer.Simple.Env
  alias Llixer.Simple.Parser

  alias ExSpirit.Parser.ExpectationFailureException

  test "Parser" do
    env = Env.new()
    assert %{error: nil, rest: "", result: "test"} = Parser.parse_expression(env, "test")
    assert %{error: nil, rest: "", result: "1"} = Parser.parse_expression(env, "1")
    assert %{error: nil, rest: "", result: "test\nnewline"} = Parser.parse_expression(env, "test\\nnewline")
    assert %{error: nil, rest: "newline", result: "test"} = Parser.parse_expression(env, "test\nnewline")
    assert %{error: nil, rest: "", result: []} = Parser.parse_expression(env, "()")
    assert %{error: nil, rest: "", result: ["test"]} = Parser.parse_expression(env, "(test)")
    assert %{error: nil, rest: "", result: ["test", "one"]} = Parser.parse_expression(env, "(test one)")
    assert %{error: nil, rest: "", result: ["1"]} = Parser.parse_expression(env, "(1)")
    assert %{error: nil, rest: "", result: ["+", "1", "2"]} = Parser.parse_expression(env, "(+ 1 2)")
  end

  defmodule ReadMacroTest do
    def test_read_macro_to_atom(context) do
      case Parser.parse_expression(context) do
        %{error: nil, result: result} = context when is_binary(result) ->
          %{context |
            result: ["atom", result]
          }
        %{error: nil, result: result} = context ->
          %{context |
            result: nil,
            error: %ArgumentError{message: "Invalid expression, must be symbol:  #{inspect result}"}
          }
      end
    end
  end

  test "Parser - Read Macro" do
    env =
      Env.new()
      |> Env.add_read_macro(":", {ReadMacroTest, :test_read_macro_to_atom, []})

    assert %{error: nil, rest: "", result: ["atom", "test"]} = Parser.parse_expression(env, ":test")
    assert %{error: %ExpectationFailureException{}, rest: "", result: nil} = Parser.parse_expression(env, ":()")
  end
end
