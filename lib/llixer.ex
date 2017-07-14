defmodule Llixer do
  @moduledoc """
  Documentation for Llixer.
  """

  @doc """
  Hello world.

  ## Examples

      #iex> Llixer.eval_expression(\"""
      #...> (+ 1 2)
      #...> \""") |> elem(1)
      #3

  """
  def eval_expression(input, opts \\ [])
  def eval_expression(input, opts) when is_binary(input) and is_list(opts) do
    env = opts[:env] || Llixer.Env.new(mapper: Llixer.Evaluator)
    case parse_expression(input, [env: env]++opts) do
      %{error: nil, rest: "", result: result} ->
        case Llixer.Evaluator.eval_expression(env, result) do
          {env, {:lit, value}} -> {env, value}
        end
      %{error: nil, rest: rest}=context -> throw {:input_not_consumed, rest, context}
      %{error: error}=context -> throw {:parsing_error, error, context}
    end
  end


  def parse_expression(input, opts \\ [])
  def parse_expression(input, opts) when is_binary(input) and is_list(opts) do
    env = opts[:env] || Llixer.Env.new()
    Llixer.Parser.parse_expression(env, input)
  end
end
