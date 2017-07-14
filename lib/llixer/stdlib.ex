defmodule Llixer.Evaluator.Stdlib do
  @moduledoc """
  The standard library of function for Llixer
  """

  alias Llixer.Env

  def i__quote(env, arg) do
    ast_to_value(env, arg)
  end

  def escape_name(name) when is_binary(name) do
    name # TODO:  Escape this
  end

  def ast_to_value(env, ast)
  def ast_to_value(env, {:integer, _meta, i}), do: {env, i}
  def ast_to_value(env, {:float, _meta, f}), do: {env, f}
  def ast_to_value(env, {:name, _meta, name}), do: {env, name}
  def ast_to_value(env, {:list, _meta, [{:name, _, "unquote"}, value]}) do
    {env, result} = Llixer.Evaluator.eval_expression(env, value)
    result = Llixer.Evaluator.get_raw_value(result)
    {env, result}
  end
  def ast_to_value(env, {:list, _meta, args}) do
    Env.map_env(env, args, &ast_to_value/2)
  end
  # def ast_to_value({:list, meta, l}), do: {:list, meta, [{:name, meta, "list"} | Enum.map(l, &ast_to_value/1)]}
  def ast_to_value(_env, ast), do: throw {:TODO, :UNHANDLED_QUOTED_AST, ast}


  def i__list(env, args) do
    {env, args}
  end

  def i__string(env, str) do
    {env, to_string(str)}
  end


  def i__fn(env, heads=[_|_]) do
    fun = throw {:TODO, :fn_heads, heads}
    {env, fun}
  end
end
