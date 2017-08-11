defmodule Llixer do
  @moduledoc """
  Documentation for Llixer.
  """

  # @doc """
  # Hello world.
  #
  # ## Examples
  #
  #     #iex> Llixer.eval_expression(\"""
  #     #...> (+ 1 2)
  #     #...> \""") |> elem(1)
  #     #3
  #
  # """
  # def eval_expression(input, opts \\ [])
  # def eval_expression(input, opts) when is_binary(input) and is_list(opts) do
  #   env = opts[:env] || Llixer.Env.new(mapper: Llixer.Evaluator)
  #   case parse_expression(input, [env: env]++opts) do
  #     %{error: nil, rest: "", result: result} ->
  #       case Llixer.Evaluator.eval_expression(env, result) do
  #         {env, {:lit, value}} -> {env, value}
  #       end
  #     %{error: nil, rest: rest}=context -> throw {:input_not_consumed, rest, context}
  #     %{error: error}=context -> throw {:parsing_error, error, context}
  #   end
  # end


  def parse_expression(input, opts \\ [])
  def parse_expression(input, opts) when is_binary(input) and is_list(opts) do
    env = opts[:env] || Llixer.Env.new(opts ++ [mapper: Llixer.AST])
    Llixer.Parser.parse_expression(env, input)
  end


  def expression_to_ast(sexpr, opts \\ []) when is_tuple(sexpr) do
    env = opts[:env] || Llixer.Env.new(opts ++ [mapper: Llixer.AST])
    Llixer.AST.sexpr_to_ast(sexpr, [env: env]++opts)
  end


  @doc ~S"""
  """
  defmacro sigil_L({:<<>>, meta, [input]}, opts) when is_binary(input) do
    line = meta[:line] || __CALLER__.line || 1
    input =
      case ?u in opts do
        true -> input
        _ -> "(" <> input <> ")"
      end
    case parse_expression(input, [line: line]++opts) do #|> IO.inspect(label: line) do
      %{error: nil, rest: "", result: sexpr} -> expression_to_ast(sexpr, to: :Elixir) #|> IO.inspect(label: :AST) #|> case do e -> e|>Macro.to_string|>IO.puts;e end
      %{error: nil, rest: rest} -> throw "Not all input consumed, remaining:  #{rest}"
      %{error: error} -> raise error
    end
  end
end
