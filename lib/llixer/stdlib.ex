defmodule Llixer.Evaluator.Stdlib do
  @moduledoc """
  The standard library of function for Llixer
  """

  alias Llixer.Env

  # def i__quote(env, arg) do
  #   ast_to_value(env, arg)
  # end

  def escape_name(name) when is_binary(name) do
    name # TODO:  Escape this
  end

  def ast_to_value(env, ast)
  def ast_to_value(env, {:integer, _meta, i}), do: {env, i}
  def ast_to_value(env, {:float, _meta, f}), do: {env, f}
  def ast_to_value(env, {:name, _meta, name}), do: {env, name}
  def ast_to_value(env, {:cmd, _meta, [{:name, _, "unquote"}, value]}) do
    {env, result} = Llixer.Evaluator.eval_expression(env, value)
    result = Llixer.Evaluator.get_raw_value(result)
    {env, result}
  end
  def ast_to_value(env, {:cmd, _meta, args}) do
    Env.map_env(env, args, &ast_to_value/2)
  end
  # def ast_to_value({:cmd, meta, l}), do: {:cmd, meta, [{:name, meta, "list"} | Enum.map(l, &ast_to_value/1)]}
  def ast_to_value(_env, ast), do: throw {:TODO, :UNHANDLED_QUOTED_AST, ast}


  # def i__list(env, args) do
  #   {env, args}
  # end
  # def i__string(env, str) do
  #   {env, to_string(str)}
  # end
  # def i__fn(env, heads=[_|_]) do
  #   fun = throw {:TODO, :fn_heads, heads}
  #   {env, fun}
  # end


  def escape_sexpr(sexpr)
  def escape_sexpr(atom) when is_atom(atom), do: {:atom, [], atom}
  def escape_sexpr(integer) when is_integer(integer), do: {:integer, [], integer}
  def escape_sexpr(string) when is_binary(string), do: {:string, [], string}
  def escape_sexpr(list) when is_list(list) do
    list = Enum.map(list, &escape_sexpr/1)
    {:list, [], list}
  end
  def escape_sexpr(tuple) when is_tuple(tuple) do
    list =
      tuple
      |> Tuple.to_list()
      |> Enum.map(&escape_sexpr/1)
    {:tuple, [], list}
  end
  def escape_sexpr(sexpr), do: throw {:UNHANDLED_SEXPR_ESCAPE, sexpr}


  def i__quote(env, {:cmd, _meta, [_quote, sexpr]}) do
    sexpr = escape_sexpr(sexpr)
    {env, sexpr}
  end

  def i__atom(env, {:cmd, _meta, [_atom, {:name, name_meta, name}]}) do
    name =
      if env.safe do
        String.to_existing_atom(name)
      else
        String.to_atom(name)
      end
    {env, {:atom, name_meta, name}}
  end

  def i__string(env, {:cmd, _meta, [_string, {:name, name_meta, name}]}) do
    {env, {:string, name_meta, name}}
  end

  def i__list(env, {:cmd, meta, [_list | args]}) do
    {env, {:list, meta, args}}
  end

  def i__tuple(env, {:cmd, meta, [_tuple | args]}) do
    {env, {:tuple, meta, args}}
  end

  def i__map(env, {:cmd, meta, [_map | args]}) do
    {env, args} =
      Env.map_env(env, args, fn
        (env, {type, type_meta, [key, value]}) when type in [:cmd, :tuple] ->
          {env, {:tuple, type_meta, [key, value]}}
        (_env, arg_sexpr) -> throw {:INVALID_MAP_ARGUMENT, arg_sexpr}
      end)
    {env, {:map, meta, args}}
  end

  def i__fn(env, {:cmd, meta, [_fn | heads]}) do
    {env, heads} =
      Env.map_env(env, heads, fn
        (env, {:cmd, head_meta, [{:cmd, _args_meta, args}, {:cmd, _guards_meta, guards}, body]}) ->
          ast = {:->, head_meta, [args, guards, body]}
          {env, ast}
        (env, {:cmd, head_meta, [{:cmd, _args_meta, args}, body]}) ->
          ast = {:->, head_meta, [args, [], body]}
          {env, ast}
        (_env, sexpr) -> throw {:INVALID_FN_HEAD, sexpr}
      end)
    {env, {:fn, meta, heads}}
  end

  def i__do(env, {:cmd, meta, [{_name, do_meta, _name_do} | body]}) do
    do_atom = {:atom, [unwrapped: true]++do_meta, :do}
    block = {:block, do_meta, body}
    {env, {:tuple, meta, [do_atom, block]}}
  end


end
