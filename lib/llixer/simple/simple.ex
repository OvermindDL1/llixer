defmodule Llixer.Simple do
  @moduledoc """
  """

  alias Llixer.Simple.Env
  alias Llixer.Simple.Parser
  alias Llixer.Simple.Evaluator
  alias Llixer.Simple.SpecialForms
  alias Llixer.Simple.Stdlib

  def read(input, opts \\ []) do
    env = env_from_opts(opts)
    case Parser.parse_expression(env, input) do
      %{error: nil, rest: rest, result: result} -> {:ok, rest, result}
      %{error: err} -> err
    end
  end

  def eval(sexprs, opts \\ []) do
    env = env_from_opts(opts)
    Evaluator.eval_sexpr(env, sexprs)
  end

  def read_eval(input, opts \\ []) do
    env = env_from_opts(opts)
    opts = [env: env] ++ opts
    case read(input, opts) do
      {:ok, "", sexpr} -> eval(sexpr, opts)
      {:ok, rest, sexpr} -> throw {:UNUSED_INPUT, rest, sexpr}
      err -> err
    end
  end

  defmacro sigil_L({:<<>>, _meta, [input]}, opts) when is_binary(input) do
    input =
      case ?u in opts do
        true -> input
        _ -> "(" <> input <> ")"
      end
    env = env_from_opts([meta_elixir: true])
    case read_eval(input, [env: env]) do
      {%Env{}, result} -> result
      err -> raise err
    end
  end


  ## Helpers

  def env_from_opts(opts \\ []) do
    case opts[:env] do
      nil ->
        env =
          Env.new()
          |> Env.push_scope(:special_forms, SpecialForms.scope())
          |> Env.push_scope(:read_macros)
          |> Stdlib.ReadMacros.add_read_macros()
        env = if(opts[:meta_elixir], do: Llixer.Simple.Elixir.add_elixir_calls(env), else: env)
        env =
          env
          |> Env.push_scope(:global)
        %{env |
          safe: opts[:safer] && true || false,
        }
      env -> env
    end
  end
end
