defmodule Llixer.AST do
  @moduledoc """
  This module converts to and from Elixir AST
  """

  alias Llixer.Env
  alias ExSpirit.TreeMap, as: TreeMap


  def sexpr_to_ast(sexpr, opts) when is_tuple(sexpr) do
    case opts[:to] do
      :Elixir ->
        {_env, ast} = to_elixir_ast(opts[:env], sexpr)
        ast
    end
  end


  defp to_elixir_ast(env, sexpr)
  defp to_elixir_ast(env, {:integer, meta, integer}) when is_integer(integer) do
    ast = {:__block__, meta, [integer]}
    # ast = integer
    {env, ast}
  end
  defp to_elixir_ast(env, {:float, meta, float}) when is_float(float) do
    ast = {:__block__, meta, [float]}
    {env, ast}
  end
  defp to_elixir_ast(env, {:atom, meta, atom}) when is_atom(atom) do
    ast =
      if meta[:unwrapped] do # At least until elixir fixes its stuff...
        atom
      else
        {:__block__, meta, [atom]}
      end
    {env, ast}
  end
  defp to_elixir_ast(env, {:string, meta, string}) when is_binary(string) do
    ast = {:__block__, meta, [string]}
    {env, ast}
  end
  defp to_elixir_ast(env, {:list, meta, args}) when is_list(args) do
    {env, args} = Env.map_env(env, args, &to_elixir_ast/2)
    ast = {:__block__, meta, [args]}
    ast = args
    {env, ast}
  end
  defp to_elixir_ast(env, {:tuple, meta, [first, second]}) do
    {env, first} = to_elixir_ast(env, first)
    {env, second} = to_elixir_ast(env, second)
    ast = {first, second}
    # ast = {:__block__, meta, [ast]}
    {env, ast}
  end
  defp to_elixir_ast(env, {:tuple, meta, args}) when is_list(args) do
    {env, args} = Env.map_env(env, args, &to_elixir_ast/2)
    ast = {:{}, meta, args}
    {env, ast}
  end
  defp to_elixir_ast(env, {:map, meta, args}) when is_list(args) do
    {env, args} =
      Env.map_env(env, args, fn
        (env, {:tuple, _meta, [key, value]}) ->
          {env, key} = to_elixir_ast(env, key)
          {env, value} = to_elixir_ast(env, value)
          {env, {key, value}}
      end)
    ast = {:%{}, meta, args}
    {env, ast}
  end
  defp to_elixir_ast(env, {:fn, meta, heads}) when is_list(heads) do
    {env, heads} =
      Env.map_env(env, heads, fn
        (env, {:->, head_meta, [args, guards, body]}) ->
          {env, args} = Env.map_env(env, args, &to_elixir_ast/2)
          {env, guards} = Env.map_env(env, guards, &to_elixir_ast/2)
          {env, head} =
            case guards do
              [] -> {env, args}
              _ ->
                guards =
                  Enum.reduce(Enum.reverse(guards), fn(guard, prior) ->
                    {:when, [], [guard, prior]}
                  end)
                head = {:when, [], args ++ [guards]}
                {env, [head]}
            end
          {env, body} = to_elixir_ast(env, body)
          {env, {:->, head_meta, [head, body]}}
      end)
      ast = {:fn, meta, heads}
      {env, ast}
  end
  defp to_elixir_ast(env, {:block, meta, body}) when is_list(body) do
    {env, body} = Env.map_env(env, body, &to_elixir_ast/2)
    ast = {:__block__, meta, body}
    {env, ast}
  end
  defp to_elixir_ast(env, {:name, meta, name}) when is_binary(name) do
    name = to_atom(env, name)
    ast = {name, meta, nil}
    {env, ast}
  end
  # Direct BEAM call
  defp to_elixir_ast(env, {:cmd, meta, [{:name, _name_meta, name} | args]} = sexpr) when is_binary(name) do
    case meta[:direct_call] || env.calls[name] do
      v when v in [nil, true] ->
        {env, name} = callee_to_elixir_ast(env, name)
        {env, args} = Env.map_env(env, args, &to_elixir_ast/2)
        ast = {name, meta, args}
        {env, ast}
      {:internal, {module, fun, arity, extra_args}} when arity === -1 or arity === length(args) ->
        {env=%Env{}, result_ast} =
          # if arity === -1 do
            apply(module, fun, [env, sexpr | extra_args])
          # else
          #   apply(module, fun, [env | args ++ extra_args])
          # end
        to_elixir_ast(env, result_ast)
    end
  end
  # Indirect BEAM call
  # defp to_elixir_ast(env, {:cmd, meta, [sexpr_call | args]} = sexpr) when is_binary(name) do
  # end
  # defp to_elixir_ast(env, {:cmd, meta, [call | args]}) do
  #   call = to_elixir_ast_call(env, call)
  #   args = Enum.map(args, &to_elixir_ast(env, &1))
  #   {env, {call, meta, args}}
  # end
  defp to_elixir_ast(_env, sexpr), do: throw {:UNHANDLED_SEXPR, sexpr}


  # defp to_elixir_ast_call(env, sexpr)
  # defp to_elixir_ast_call(env, {:name, meta, name}) when is_binary(name) do
  #   name = to_atom(env, name)
  # end
  # defp to_elixir_ast_call(env, {type, _meta, _arg} = sexpr) when type in [:cmd], do: to_elixir_ast(env, sexpr)
  # defp to_elixir_ast_call(_env, sexpr), do: throw {:UNHANDLED_SEXPR_CALL, sexpr}


  defp callee_to_elixir_ast(env, name) when is_binary(name) do
    case String.split(name, ".") |> Enum.reverse() do
      [fun] -> {env, to_atom(env, fun)}
      [fun | module] ->
        fun = to_atom(env, fun)
        module = to_atom(env,
          module
          |> Enum.reverse()
          |> Enum.join(".")
          )
        ast = {:., [], [module, fun]}
        {env, ast}
    end
  end


  defp to_atom(env, str) when is_binary(str) do
    if env.safe do
      String.to_existing_atom(str)
    else
      String.to_atom(str)
    end
  end



  def default_read_macros(), do: unquote(Macro.escape(
    TreeMap.new()
    |> TreeMap.add("`", {Llixer.SyntaxHelpers, :read_macro__quote, []})
    |> TreeMap.add(",", {Llixer.SyntaxHelpers, :read_macro__unquote, []})
    |> TreeMap.add("\"", {Llixer.SyntaxHelpers, :read_macro__string, []})
  ))

  def default_calls(), do: %{
    "quote" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__quote, 1, []}),
    "list" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__list, -1, []}),
    "tuple" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__tuple, -1, []}),
    "map" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__map, -1, []}),
    "atom" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__atom, 1, []}),
    "string" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__string, 1, []}),
    "fn" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__fn, -1, []}),
    "do" => Env.define_icall({Llixer.Evaluator.Stdlib, :i__do, -1, []}),
  }

end
